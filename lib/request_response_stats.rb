# File: lib/request_response_stats.rb

require "request_response_stats/version"
require_relative 'request_response_stats/request_response'
require_relative 'request_response_stats/custom_client'
require_relative 'request_response_stats/controller_concern'

module RequestResponseStats
  # override to set it to false if you want to capture inbound requests
  RR_INBOUND_STATS = true unless defined? RR_INBOUND_STATS
  
  # override to set it to true if you want to capture inbound requests
  RR_OUTBOUND_STATS = true unless defined? RR_OUTBOUND_STATS
  
  if self.method_defined? :custom_alert_code
    # override to define the code that should be run on encountring alert conditions
    def self.custom_alert_code(data)
      raise StandardError, "Undefined custom alter code"
    end
  end
end

##### Examples: #####

## Checking current redis data:
=begin
 require 'request_response_stats'
 include RequestResponseStats
 rrs = RequestResponse.new(nil, nil)
 ap rrs.redis_record.hashify_all_data
 ap rrs.redis_record.hashify_all_data.size
=end

## Manually moving data from Redis to Mongo:
# ap rrs.move_data_from_redis_to_mongo

## Deleting data from Redis and Mongo:
# rrs.redis_record.all_keys.each{|k| rrs.redis_record.del k}
# ReqResStat.all.delete_all

## Getting stats from Mongo:
=begin
 ap ReqResStat.all.size
 ap ReqResStat.all.first
 t = Time.now
 ReqResStat.get_max(:max_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
 ReqResStat.get_avg(:avg_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
 ReqResStat.get_max(:min_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
 ap ReqResStat.get_details(:max_time, t - 2.day, t, nil, 6.hours)
 ap ReqResStat.get_details(:max_time, t - 2.day, t, :max, 6.hours)
 ap ReqResStat.get_details(:max_time, t - 2.day, t, :min, 6.hours)
 ap ReqResStat.get_details(:max_time, t - 2.day, t, :sum, 6.hours)
 ap ReqResStat.get_details(:max_time, t - 2.day, t, :avg, 6.hours)
=end

