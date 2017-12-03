# File: config/initializers/request_response_stat_config.rb

require 'request_response_stats'
include RequestResponseStats

# Note: The namespace `RequestResponseStats` is requried if you are not including `RequestResponseStats` module
# Set `RR_INBOUD_STATS` to false (default is `true`) to not capture inbound request stats
# RequestResponseStats::RR_INBOUND_STATS = true
# Set `RR_OUTBOUND_STATS` to false (default is `true`) to not capture inbound request stats
# RequestResponseStats::RR_OUTBOUND_STATS = true

# Configure custom alert code
# Note: Ideally we should pass below custom code as block while we instantiate `RequestResponse`. But,
# as we are using the same setting for outbound calls as well.
module RequestResponseStats
  def self.custom_alert_code(data)
    # Custom alert code
    # current_time = Time.now.utc
    # service = NotificationService.new(activity: "request_response_alert", uuid: "ReqResNotification-#{current_time.to_s}-#{current_time.nsec}".gsub(" ", "_"))
    # service.send_req_res_threshold_crossed_alarm_email(data)
  end
end

# Enable incoming requests to be captured
# Add `include RequestResponseStats::ControllerConcern` to the controller whose actions and actions in sub-classes are to be logged for request response stats
# Example:
# module Api
#   class ApiController < ActionController::Base
#     include RequestResponseStats::ControllerConcern
#   end
# end


# Note: Below block is commented out with `=begin` and `=end`
# You can uncomment the clients that are used in your application

=begin
# Configure popular REST and SOAP libraries
# Client libraries
require 'rest-client'
require 'httparty'
require 'savon'

# Enable outbound requests to be capture
module RestClient
  include CustomClient
end

module HTTParty
  include CustomClient
end

module Savon
  include CustomClient

  def self.custom_uri_key
    :wsdl
  end

  class Client
    alias_method("#{Savon::RENAME_NAMESPACE}call".to_sym, :call)

    def call(operation_name, locals={}, &block)
      Savon.log_request_response_stats(operation_name, "locals") do
        public_send("#{Savon::RENAME_NAMESPACE}call".to_sym, operation_name, locals, &block)
      end
    end
  end
end
=end
