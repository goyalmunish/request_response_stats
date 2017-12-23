# File: lib/request_response_stats/request_response.rb

require_relative 'redis_record'
require_relative 'req_res_stat'

module RequestResponseStats
  class RequestResponse
    attr_accessor :request, :response
    attr_accessor :redis_record
    attr_accessor :redis, :mongoid_doc_model, :gather_stats

    LONGEST_REQ_RES_CYCLE = 2.hours
    SECONDS_PRECISION = 3
    MEMORY_PRECISION = 0
    SYS_CALL_FREQ = 60.seconds

    # Set `GROUP_STATS_BY_TIME_DURATION` to `false` if no time based grouping is required, otherwise you can set it to value such as `1.minute` (but within a day)
    GROUP_STATS_BY_TIME_DURATION = 1.minute

    # Here:
    # `redis_connection` is connection to redis db
    # `mongoid_doc_model` is Mongoid::Document model which specifies document schema compatible to data structure in redis
    # if `gather_stats` is `false`, they new data won't be added to the redis db
    def initialize(req=nil, res=nil, opts={redis_connection: $redis, mongoid_doc_model: ReqResStat, gather_stats: true})
      @request = req
      @response = res
      @redis = opts[:redis_connection]
      @mongoid_doc_model = opts[:mongoid_doc_model]
      @gather_stats = opts[:gather_stats]

      @redis_record = RedisRecord

      # adding behavior to dependents
      temp_redis = @redis  # TODO: check why using @redis directly is not working. Do instance variable have specifal meaning inside defin_singleton_method block?
      @redis_record.define_singleton_method(:redis) { temp_redis }
      @redis_record.define_singleton_method(:group_stats_by_time_duration) { GROUP_STATS_BY_TIME_DURATION }
    end

    # captures request info that will be used at the end of request-response cycle
    # note that the captured infomation is saved only temporarily
    def capture_request_response_cycle_start_info
      return gather_stats unless gather_stats

      # get system info
      current_time = get_system_current_time

      # temporarily save request info
      req_info = {
        req_object_id: request.object_id,
        res_object_id: response.object_id,
        server_name: (request.env["SERVER_NAME"] rescue "some_server_name"),
        req_path: (request.path rescue "some_path"),
        req_http_verb: (request.method rescue "some_method"),
        req_time: current_time,  # implicit convertion to integer
        req_url: (request.url rescue "some_url"),
        req_format: (request.parameters["format"] rescue "some_format"),
        req_controller: (request.parameters["controller"] rescue "some_controller"),
        req_action: (request.parameters["action"] rescue "some_action"),
        remote_ip: (request.remote_ip rescue "some_ip"),
        gc_stat: get_gc_stat,
      }
      redis_req_key_name = redis_record.req_key(get_server_hostname, req_info[:req_object_id])
      redis_record.jsonified_set(redis_req_key_name, req_info, {ex: LONGEST_REQ_RES_CYCLE}, {strict_key_check: false})

      # return key_name
      redis_req_key_name
    end

    # captures respose info and makes use of already captured request info
    # to save info about current request-response cycle to redis
    def capture_request_response_cycle_end_info(capture_error: false)
      return gather_stats unless gather_stats

      # get system info
      current_time = get_system_current_time
      current_used_memory = get_system_used_memory_mb
      current_swap_memory = get_system_used_swap_memory_mb
      current_hostname = get_server_hostname
      current_gc_stat = get_gc_stat

      res_info = {
        req_object_id: request.object_id,
        res_object_id: response.object_id,
        res_time: current_time,
      }

      # fetching temporary request info
      # return false if temporary request info cannot be found
      redis_req_key_name = redis_record.req_key(get_server_hostname, res_info[:req_object_id])
      req_info = ActiveSupport::HashWithIndifferentAccess.new(redis_record.parsed_get(redis_req_key_name))
      return false if req_info == {}
      redis_record.del redis_req_key_name

      # generating request-response-cycle info
      req_res_info = {
        key_name: nil,
        # server_name: req_info[:server_name],
        server_name: current_hostname,
        api_name: req_info[:req_path],
        api_verb: req_info[:req_http_verb],
        api_controller: req_info[:req_controller],
        api_action: req_info[:req_action],
        request_count: 0,
        min_time: nil,
        max_time: nil,
        avg_time: 0,
        start_time: nil,  # slot starting time
        end_time: nil,  # slot ending time
        error_count: 0,
        min_used_memory_MB: nil,
        max_used_memory_MB: nil,
        avg_used_memory_MB: 0,
        min_swap_memory_MB: nil,
        max_swap_memory_MB: nil,
        avg_swap_memory_MB: 0,
        avg_gc_stat_diff: Hash.new(0),
        min_gc_stat_diff: {},
        max_gc_stat_diff: {},
      }
      redis_req_res_key_name = redis_record.req_res_key(req_res_info[:server_name], req_res_info[:api_name], req_res_info[:api_verb])
      req_res_info[:key_name] = redis_req_res_key_name
      req_res_info[:start_time], req_res_info[:end_time] = redis_record.get_slot_range_for_key(redis_req_res_key_name).map(&:to_s)
      req_res_info_parsed = redis_record.parsed_get(redis_req_res_key_name)
      req_res_info = if req_res_info_parsed.present?
        # making use of existing value from db
        ActiveSupport::HashWithIndifferentAccess.new(req_res_info_parsed)
      else
        # using default value
        ActiveSupport::HashWithIndifferentAccess.new(req_res_info)
      end
      current_cycle_time = (res_info[:res_time] - req_info[:req_time]).round(SECONDS_PRECISION)
      current_gc_stat_diff = get_gc_stat_diff(req_info[:gc_stat], current_gc_stat)
      req_res_info[:min_time] = [req_res_info[:min_time], current_cycle_time].compact.min
      req_res_info[:max_time] = [req_res_info[:max_time], current_cycle_time].compact.max
      req_res_info[:avg_time] = ((req_res_info[:avg_time] * req_res_info[:request_count] + current_cycle_time)/(req_res_info[:request_count] + 1)).round(SECONDS_PRECISION)
      req_res_info[:min_used_memory_MB] = [req_res_info[:min_used_memory_MB], current_used_memory].compact.min
      req_res_info[:max_used_memory_MB] = [req_res_info[:max_used_memory_MB], current_used_memory].compact.max
      req_res_info[:avg_used_memory_MB] = ((req_res_info[:avg_used_memory_MB] * req_res_info[:request_count] + current_used_memory)/(req_res_info[:request_count] + 1)).round(MEMORY_PRECISION)
      req_res_info[:min_swap_memory_MB] = [req_res_info[:min_swap_memory_MB], current_swap_memory].compact.min
      req_res_info[:max_swap_memory_MB] = [req_res_info[:max_swap_memory_MB], current_swap_memory].compact.max
      req_res_info[:avg_swap_memory_MB] = (req_res_info[:avg_swap_memory_MB] * req_res_info[:request_count] + current_swap_memory)/(req_res_info[:request_count] + 1)
      req_res_info[:min_gc_stat_diff] = get_min_max_sum_gc_stat_diff(:min, req_res_info[:min_gc_stat_diff], current_gc_stat_diff)
      req_res_info[:max_gc_stat_diff] = get_min_max_sum_gc_stat_diff(:max, req_res_info[:min_gc_stat_diff], current_gc_stat_diff)
      req_res_info[:avg_gc_stat_diff] = get_avg_gc_stat_diff(req_res_info[:request_count], req_res_info[:min_gc_stat_diff], current_gc_stat_diff)
      req_res_info[:request_count] += 1  # Note: updation of `request_count` should be the last

      # if error is raised
      if capture_error
        req_res_info[:error_count] += 1
      end

      # saving request-respose-cycle info to redis db
      redis_record.jsonified_set(redis_req_res_key_name, req_res_info)

      # return request-response-cycle info key
      redis_req_res_key_name
    end

    # captures error info
    # it is called if an exception is raised, and it in turns calls capture_request_response_cycle_end_info with capture_error: true
    def capture_request_response_cycle_error_info
      capture_request_response_cycle_end_info(capture_error: true)
    end

    # moves data from redis to mongo
    # only freezed and PUBLIC keys are moved
    def move_data_from_redis_to_mongo(at_once=true)
      if at_once
        # multiple records will be inserted to mongodb at once
        # this is to minimize the index creation time
        values = []
        redis_keys = []
        redis_record.freezed_keys.each do |redis_key|
          values << redis_record.formatted_parsed_get_for_mongo(redis_key)
          redis_keys << redis_key
        end
        mongoid_doc_model.create(values)
        redis_record.del(*redis_keys) if redis_keys.size > 0

        redis_keys.size
      else
        # records will be inserted to mongo one at a time
        # corresponding key from redis will be deleted only after successful creation of mongodb record
        moved_keys = redis_record.freezed_keys.select do |redis_key|
          value = redis_record.formatted_parsed_get_for_mongo(redis_key)
          mongo_doc = mongoid_doc_model.create(value)
          redis_record.del redis_key if mongo_doc
          mongo_doc
        end

        moved_keys.size
      end
    end

    private

    # returns current time
    def get_system_current_time
      Time.now.to_f.round(SECONDS_PRECISION)
    end

    # returns current system memory
    # it uses `free` command to capture system memory info
    def get_system_memory_info_mb
      key_name = redis_record.support_key(get_server_hostname, [get_server_hostname, "memory"].join("_"))
      value = ActiveSupport::HashWithIndifferentAccess.new(redis_record.parsed_get key_name)
      return_value = if value == {}
        mem_info = (`free -ml`).split(" ") rescue []
        used_memory = mem_info[8].strip.to_i rescue 0
        used_swap_memory = mem_info[27].strip.to_i rescue 0
        data = {used_memory: used_memory, used_swap_memory: used_swap_memory}
        redis_record.set(key_name, data.to_json, {ex: SYS_CALL_FREQ})
        data
      else
        value
      end

      return_value
    end

    # returns the difference (new - old) in gc_stat
    def get_gc_stat_diff(old_gc_stat, new_gc_stat)
      stat_diff = {}
      gc_keys = new_gc_stat.keys.map{ |k| k.to_s.to_sym }
      gc_keys.each do |key|
        if old_gc_stat[key] && new_gc_stat[key]
          stat_diff[key] = new_gc_stat[key] - old_gc_stat[key]
        else
          stat_diff[key] = 0
        end
      end

      stat_diff
    end

    # stat_type can be :min, :max, :sum
    def get_min_max_sum_gc_stat_diff(stat_type, old_gsd, new_gsd)
      stat_type = stat_type.to_s.to_sym
      stat = {}
      stat_keys = new_gsd.keys.map{ |k| k.to_s.to_sym }
      stat_keys.each do |key|
        if [:min, :max, :sum].include?(stat_type)
          stat[key] = [new_gsd[key], old_gsd[key]].compact.public_send(stat_type)
        else
          "Invalid :stat_type"
        end
      end

      stat
    end

    def get_avg_gc_stat_diff(existing_request_count, old_gsd, new_gsd)
      stat_type = stat_type.to_s
      stat = {}
      stat_keys = new_gsd.keys.map{ |k| k.to_s.to_sym }
      stat_keys.each do |key|
        stat[key] = (new_gsd[key] * existing_request_count +  old_gsd[key])/(existing_request_count + 1)
      end

      stat
    end

    # returns system used memory
    # uses `get_system_memory_info` to get the info
    def get_system_used_memory_mb
      # (`free -ml | grep 'Mem:' | awk -F' ' '{ print $3 }'`.strip.to_i rescue 0).round(MEMORY_PRECISION)
      get_system_memory_info_mb[:used_memory]
    end

    # returns used swap memory
    # uses `get_system_memory_info` to get the info
    def get_system_used_swap_memory_mb
      # (`free -ml | grep 'Swap:' | awk -F' ' '{ print $3 }'`.strip.to_i rescue 0).round(MEMORY_PRECISION)
      get_system_memory_info_mb[:used_swap_memory]
    end

    # returns system hostname
    # uses linux `hostname` command to get the info
    def get_server_hostname
      (`hostname`).strip
    end

    def get_gc_stat
      GC.stat
    end
  end
end


