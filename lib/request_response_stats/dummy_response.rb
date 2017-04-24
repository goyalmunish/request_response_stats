# File: lib/request_response_stats/dummy_response.rb

module RequestResponseStats
  class DummyRequest
    attr_accessor :path, :method, :parameters

    def initialize(options)
      @path = options[:path]
      @method = options[:method]
      @controller = options[:parameters].try(:[], "controller") || "external_controller"
      @action = options[:parameters].try(:[], "action") || "external_action"
      @parameters = {"controller" => @controller, "action" => @action}
    end
  end
end
