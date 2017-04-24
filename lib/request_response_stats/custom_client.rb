# File: lib/request_response_stats/custom_client.rb

require_relative 'request_response'
require_relative 'dummy_request'
require_relative 'dummy_response'

module RequestResponseStats
  module CustomClient
    RENAME_NAMESPACE = "original_"
    RENAMED_METHODS = [:get, :post, :patch, :put, :delete, :head, :client]
    MAX_URL_LENGTH = 250  # Note that value of -1 will include whole of the url

    # By default args is assumed to be an array with first element as uri
    # If args is an hash contained within one-element array, then you can specify the key
    # that is to be used to fetch the uri
    def custom_uri_key
      false
    end

    def method_missing(name, *args, &block)
      if RENAMED_METHODS.include?(name)
        resp = log_request_response_stats(name, args) { self.public_send("#{RENAME_NAMESPACE}#{name.to_s}".to_sym, *args, &block) }
        return resp
      else
        super
      end
    end
    # module_function :method_missing

    def log_request_response_stats(name, args, &original_call)
      if defined?(RR_OUTBOUND_STATS) && RR_OUTBOUND_STATS
        begin
          uri = args.is_a?(Array) ? args.first : args
          uri = uri[custom_uri_key] if (uri.is_a?(Hash) && custom_uri_key && uri[custom_uri_key])
          sanitized_uri = uri.to_s[0..(MAX_URL_LENGTH - 1)]
          rrs = RequestResponse.new(
            DummyRequest.new({method: name, path: sanitized_uri}),
            DummyResponse.new,
            {redis_connection: $redis, gather_stats: true, mongoid_doc_model: ReqResStat}
          )
          rrs.capture_request_response_cycle_start_info
          resp = original_call.call
          rrs.capture_request_response_cycle_end_info
          return resp
        rescue Exception => ex
          # Rails.logger.info "Following exception is raised:"
          # Rails.logger.info ex
          rrs.try(:capture_request_response_cycle_error_info)
          raise ex
        end
      else
        resp = original_call.call
      end
    end
    # module_function :log_request_response_stats

    def self.included(base)
      class << base
        RENAMED_METHODS.each do |key|
          if method_defined?(key)
            alias_method("#{RENAME_NAMESPACE}#{key.to_s}".to_sym, key)
            remove_method key
          end
        end
      end
      base.class_eval do
        const_set("RENAME_NAMESPACE", RENAME_NAMESPACE)
        const_set("RENAMED_METHODS", RENAMED_METHODS)

        module_function :method_missing
        module_function :log_request_response_stats
        module_function :custom_uri_key
      end
    end
  end
end
