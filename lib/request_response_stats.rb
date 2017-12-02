# File: lib/request_response_stats.rb

# library files
require "request_response_stats/version"
require_relative 'request_response_stats/request_response'
require_relative 'request_response_stats/custom_client'
require_relative 'request_response_stats/controller_concern'
require_relative 'request_response_stats/req_res_stat'

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
