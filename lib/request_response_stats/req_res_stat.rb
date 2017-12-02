# File: app/models/req_res_stat.rb
# File: lib/request_response_stats/req_res_stat.rb

require 'mongoid'

class RequestResponseStats::ReqResStat
  include Mongoid::Document
  # include Mongoid::Timestamps

  store_in collection: "statsReqRes"

  field :key_name, type: String
  field :server_name, type: String
  field :api_name, type: String
  field :api_verb, type: String
  field :api_controller, type: String
  field :api_action, type: String
  field :request_count, type: Integer
  field :min_time, type: Float
  field :max_time, type: Float
  field :avg_time, type: Float
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :error_count, type: Integer
  field :min_used_memory_MB, type: Integer
  field :max_used_memory_MB, type: Integer
  field :avg_used_memory_MB, type: Integer
  field :min_swap_memory_MB, type: Integer
  field :max_swap_memory_MB, type: Integer
  field :avg_swap_memory_MB, type: Integer
  field :avg_gc_stat_diff, type: Hash
  field :min_gc_stat_diff, type: Hash
  field :max_gc_stat_diff, type: Hash

  DEFAULT_STATS_GRANULARITY = 1.hour
  PERCISION = 2

  def server_plus_api
    [server_name, api_name, api_verb].join("_")
  end

  class << self
    # Note:
    # `start_time` and `end_time` are Time objects
    # `start_time` in inclusive but `end_time` is not
    def get_within(start_time, end_time)
      where(:start_time.gte => start_time, :end_time.lt => end_time)
    end

    # wrapper around `get_stat` for :sum stat
    def get_sum(key, start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      get_stat("sum", key, start_time, end_time, granularity)
    end

    # wrapper around `get_stat` for :min stat
    def get_min(key, start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      get_stat("min", key, start_time, end_time, granularity)
    end

    # wrapper around `get_stat` for :max stat
    def get_max(key, start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      get_stat("max", key, start_time, end_time, granularity)
    end

    # wrapper around `get_stat` for :avg stat
    def get_avg(key, start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      data = get_stat("sum", key, start_time, end_time, granularity)
      data.each do |e|
        e[:stat_type] = "avg"
        if e[:count] != 0
          e[:data] = (e[:data] * 1.0 / e[:count]).try(:round, PERCISION)
        else
          e[:data] = 0
        end

      end
      data
    end

    # set `stat_type` as `nil` to return grouped but uncompacted data
    # otherwise, you can set `stat_type` as :sum, :max, :min, :avg to get grouped data
    def get_details(key, start_time, end_time, stat_type = nil, granularity = DEFAULT_STATS_GRANULARITY)
      # get ungrouped data
      stat_type = stat_type.to_s.to_sym if stat_type
      key = key.to_s.to_sym
      relevant_records = get_within(start_time, end_time)
      time_ranges = get_time_ranges(start_time, end_time, granularity)
      stats = time_ranges.map do |time_range|
        data_for_time_range = relevant_records.get_within(*time_range.values).map{ |r|
          {server_plus_api: r.server_plus_api, data: r[key], key_name: r.key_name}
        }
        {data: data_for_time_range, **time_range}
      end

      # grouping data by :server_plus_api
      stats.each do |r|
        data = r[:data]
        data = data.map{ |e| {server_plus_api: e[:server_plus_api], data: e[:data]} }
        data = data.group_by { |e| e[:server_plus_api] }
        r[:data] = data
      end

      # calculating grouped value based on stat_type
      if stat_type
        if [:sum, :min, :max].include? stat_type

          # calculate grouped value
          stats.each do |r|
            data = r[:data]
            data = data.map do |k, v|
              # {server_plus_api: k, data: v.map{|e| e[:data]}}
              element_data = v.map{|e| e[:data]}
              {server_plus_api: k, count: element_data.size, data: element_data.compact.public_send(stat_type).try(:round, PERCISION)}
            end
            r[:data] = data
          end

          stats
        elsif stat_type == :avg
          data = get_details(key, start_time, end_time, stat_type = :sum, granularity)
          data.each do |r|
            r[:data].each do |e|
              e[:data] = (e[:data] * 1.0 / e[:count]).try(:round, PERCISION)
            end
          end

          data
        else
          "This :stat_type is not supported"
        end
      else
        stats
      end
    end

    private

    def get_time_ranges(start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      slots = (((end_time - start_time) / granularity).ceil) rescue 0
      current_start_time = start_time
      time_ranges = (1..slots).map do |slot|
        value = {start_time: current_start_time, end_time: current_start_time + granularity}
        current_start_time += granularity

        value
      end
      time_ranges[-1][:end_time] = end_time if time_ranges[-1] && (time_ranges[-1][:end_time] > end_time)

      time_ranges
    end

    # stat: ["sum", "min", "max"]
    # Note that [].sum is 0, whereas, [].min and [].max is nil
    def get_stat(stat_type, key, start_time, end_time, granularity = DEFAULT_STATS_GRANULARITY)
      stat_type = stat_type.to_s.to_sym
      key = key.to_s.to_sym
      relevant_records = get_within(start_time, end_time)
      time_ranges = get_time_ranges(start_time, end_time, granularity)
      stats = time_ranges.map do |time_range|
        time_range_data = relevant_records.get_within(*time_range.values).pluck(key)
        data = time_range_data.compact.public_send(stat_type).try(:round, PERCISION)
        {key: key, stat_type: stat_type, data: data, count: time_range_data.size, **time_range}
      end

      stats
    end

  end

end
