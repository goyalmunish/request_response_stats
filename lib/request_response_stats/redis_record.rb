# File: lib/request_response_stats/redis_record.rb

require 'active_support/time'
require 'active_support/core_ext/hash/indifferent_access'
require 'json'

module RequestResponseStats
  class RedisRecord
    attr_accessor :key, :value

    REDIS_RR_KEY_NAMESPACE = "api_req_res"

    PERMITTED_KEYS = [
      :key_name,
      :server_name,
      :api_name,
      :api_verb,
      :api_controller,
      :api_action,
      :request_count,
      :min_time,
      :max_time,
      :avg_time,
      :start_time,
      :end_time,
      :error_count,
      :min_used_memory_MB,
      :max_used_memory_MB,
      :avg_used_memory_MB,
      :min_swap_memory_MB,
      :max_swap_memory_MB,
      :avg_swap_memory_MB,
      :avg_gc_stat_diff,
      :min_gc_stat_diff,
      :max_gc_stat_diff,
    ].map(&:to_s)

    AT_MAX_TIME = nil unless defined? AT_MAX_TIME
    AT_ERROR_COUNT = nil unless defined? AT_ERROR_COUNT
    AT_MAX_SWAP_MEMORY_MB = nil unless defined? AT_MAX_SWAP_MEMORY_MB
    ALERT_THRESHOLD = {
      max_time: AT_MAX_TIME || 30,
      error_count: AT_ERROR_COUNT || 2,
      max_swap_memory_MB: AT_MAX_SWAP_MEMORY_MB || 200,
    }.stringify_keys

    class << self

      # returns the redis connection
      # this method must be redefined for `RedisRecord` to be useable
      def redis
        raise StandardError, "UNDEFINED #{__method__}"
      end

      # get value from redis
      # wrapper from redis' `get` method
      def get(key)
        redis.get(key)
      end

      # set value to redis
      # wrapper from redis' `set` method
      def set(key, value, options={})
        redis.set(key, value, options)
      end

      # delete value from redis
      # wrapper from redis' `del` method
      def del(key)
        redis.del(key)
      end

      # returns all request_response_stats relevant redis keys
      # by default only PUBLIC keys are returned
      def all_keys(opts={})
        support = opts[:support] || false
        if support
          regex = /^#{REDIS_RR_KEY_NAMESPACE}/
        else
          regex = /^#{REDIS_RR_KEY_NAMESPACE}_PUBLIC/
        end

        redis.keys.select{|k| k =~ regex}.sort.reverse
      end

      # return parsed value from redis
      def parsed_get(key)
        JSON.parse(redis.get(key) || "{}")
      end

      # it returns parsed result into the format required for Mongo dump
      def formatted_parsed_get_for_mongo(key)
        data = parsed_get(key)
        data["start_time"] = date_time_str_to_obj(data["start_time"])
        data["end_time"] = date_time_str_to_obj(data["end_time"])

        data
      end

      # returns collection of all relevant PUBLIC request_response_stats data from redis
      def hashify_all_data(opts={})
        support = opts[:support] || false
        req_res_stat = ActiveSupport::HashWithIndifferentAccess.new
        all_keys(support: support).each do |key|
          req_res_stat[key] = ActiveSupport::HashWithIndifferentAccess.new(parsed_get key)
        end

        req_res_stat
      end

      # flushes all request_response_stats data from redis
      def flush_all_keys
        redis.del(*all_keys(support: true)) if all_keys.present?
      end

      # it has to be overridden
      def group_stats_by_time_duration
        raise StandardError, "UNDEFINED #{__method__}"
      end

      def support_key(server_name, key_name="default")
        [REDIS_RR_KEY_NAMESPACE, "SUPPORT", server_name.to_s, key_name].join("_")
      end

      def req_key(server_name, req_object_id)
        support_key(server_name, ["REQ_OBJ", req_object_id].join("_"))
      end

      def req_res_key(server_name, api_name, api_http_verb)
        ["#{REDIS_RR_KEY_NAMESPACE}_PUBLIC_#{server_name}_#{api_name}_#{api_http_verb}", get_time_slot_name].compact.join("_")
      end

      def get_slot_range_for_key(redis_key)
        date_slot_string = redis_key.split("_")[-1]

        get_slot_range_for_date_slot_string(date_slot_string)
      end

      # set jsonified value to redis and raise alerts
      def jsonified_set(key, value, options={}, custom_options={strict_key_check: true})
        value.select!{|k,v| PERMITTED_KEYS.include? k.to_s} if custom_options[:strict_key_check]

        # set jsonified value to redis
        redis.set(key, value.to_json, options)

        # get alerts collection
        alerts = ALERT_THRESHOLD.select{ |k, v| value[k] >= v if value[k] }.map{|k,v| {
          redis_key: key,
          alarm_key: k,
          alarm_value: v,
          actual_value: value[k]
        }}
        alerts_data = {data: alerts}.to_json
        raise_alert(alerts_data) if alerts.present?

        # return alerts
        alerts_data
      end

      # returns all PUBLIC request_response_stats related freezed keys from redis
      # freezed key: redis key which will no longer be updated
      # only freezed keys are eligible to be moved to mongo
      def freezed_keys
        all_keys.map{|k| self.new(k)}.select{|k| k.is_key_freezed?}.map{|rr| rr.key}
      end

      # lets you fetch records for given conditions from redis
      def query(params={})
        # to implement
      end

      private

      # Example: for a value of `1.hour` for `group_stats_by_time_duration`, the data for each endpoint is
      # divided into `1 day / 1.hour = 24` time slots within a day
      def get_time_slot_name(current_time = Time.now)
        current_time_utc = current_time.utc
        seconds_since_beginning_of_today = (current_time_utc - Time.utc(current_time_utc.year, current_time_utc.month, current_time_utc.day)).to_i
        # seconds_in_a_day = 24 * 60 * 60
        num_of_slots_in_a_day = 24.hours / group_stats_by_time_duration
        seconds_in_a_time_slot = group_stats_by_time_duration.seconds.to_i
        current_slot = (seconds_since_beginning_of_today / seconds_in_a_time_slot).to_i
        slot_str_length = num_of_slots_in_a_day.to_s.size
        current_slot_name = "%0#{slot_str_length}d" % current_slot
        current_slot_full_name = [
          current_time_utc.year,
          "%02d" % current_time_utc.month,  # current_time_utc.month
          "%02d" % current_time_utc.day,  # current_time_utc.day
          current_slot_name
        ].join("-")

        current_slot_full_name
      end

      # returns time range of given date_slot_stringe
      # which is [start_time_of_slot, end_time_of_slot]
      def get_slot_range_for_date_slot_string(date_slot_string)
        year_num, month_num, date_num, slot_num = date_slot_string.split("-").map(&:to_i)
        time = Time.utc(year_num, month_num, date_num)

        # num_of_slots_in_a_day = 24.hours / group_stats_by_time_duration
        seconds_in_a_time_slot = group_stats_by_time_duration.seconds.to_i
        seconds_already_passed = slot_num * seconds_in_a_time_slot
        starting_time = time + seconds_already_passed
        ending_time = starting_time + seconds_in_a_time_slot

        [starting_time, ending_time]
      end

      # Input example: "2017-11-06 09:01:00 UTC"
      def date_time_str_to_obj(date_time_str)
        date, time, zone = date_time_str.split(" ")
        date = date.split("-").map(&:to_i)
        time = time.split(":").map(&:to_i)
        zone = "+00:00" if zone == ["UTC"]
        DateTime.new(*date, *time, zone)
      end

      def raise_alert(data)
        name.split("::")[0].constantize.custom_alert_code(data)
      end

    end

    def initialize(key, value=nil)
      @key = key
      @value = value
    end

    # if a key is freezed then no more data will be written to it
    def is_key_freezed?
      return nil unless self.class.group_stats_by_time_duration

      self.class.get_slot_range_for_key(key)[1] < Time.now
    end

  end
end
