# File: lib/request_response_stats/controller_concern.rb

require_relative 'request_response'

module RequestResponseStats
  module ControllerConcern
    def self.included(base)
      include RequestResponseStats

      base.class_eval do
        around_action :log_request_response_stats
        # before_action :log_request_response_stats_before
        # after_action :log_request_response_stats_end

        def log_request_response_stats
          if defined?(RR_INBOUND_STATS) && RR_INBOUND_STATS
            begin
              rrs = RequestResponse.new(request, response, {redis_connection: $redis, gather_stats: true, mongoid_doc_model: ReqResStat})
              rrs.capture_request_response_cycle_start_info
              if block_given?
                yield
              else
                raise StandardError, "No block received. Investigate!"
              end
              rrs.capture_request_response_cycle_end_info
            rescue Exception => ex
              rrs.try(:capture_request_response_cycle_error_info)
              raise ex
            end
          else
            yield
          end
        end

      end

    end
  end
end
