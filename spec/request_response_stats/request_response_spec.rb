require "spec_helper"
require_relative '../../lib/request_response_stats/dummy_request'
require_relative '../../lib/request_response_stats/dummy_response'

RSpec.describe RequestResponseStats::RequestResponse do
  subject { RequestResponseStats::RequestResponse }

  before(:each) do
    allow_any_instance_of(Kernel).to receive(:`).with("free -ml").and_return(nil)
    allow_any_instance_of(Kernel).to receive(:`).with("hostname").and_return("Munishs-MacBook-Pro")
  end

  it "defines LONGEST_REQ_RES_CYCLE as an ActiveSupport::Duration" do
    expect(subject::LONGEST_REQ_RES_CYCLE).not_to be nil
    expect(subject::LONGEST_REQ_RES_CYCLE).to be_a_kind_of(ActiveSupport::Duration)
  end

  it "defines SECONDS_PRECISION as an Integer value" do
    expect(subject::SECONDS_PRECISION).not_to be nil
    expect(subject::SECONDS_PRECISION).to be_a_kind_of(Integer)
  end

  it "defines MEMORY_PRECISION as an Integer value" do
    expect(subject::MEMORY_PRECISION).not_to be nil
    expect(subject::MEMORY_PRECISION).to be_a_kind_of(Integer)
  end

  it "defines SYS_CALL_FREQ as an ActiveSupport::Duration" do
    expect(subject::SYS_CALL_FREQ).not_to be nil
    expect(subject::SYS_CALL_FREQ).to be_a_kind_of(ActiveSupport::Duration)
  end

  it "defines GROUP_STATS_BY_TIME_DURATION as an ActiveSupport::Duration" do
    expect(subject::GROUP_STATS_BY_TIME_DURATION).not_to be nil
    expect(subject::GROUP_STATS_BY_TIME_DURATION).to be_a_kind_of(ActiveSupport::Duration)
  end

  context ".new" do
    it "sets #redis" do
      redis_record = double("redis_record")
      rr = subject.new(nil, nil, {redis_connection: redis_record})
      expect(rr.redis).to eq(redis_record)
    end

    it "sets #mongoid_doc_model" do
      mongoid_doc_model = double("mongoid_doc_model")
      rr = subject.new(nil, nil, {mongoid_doc_model: mongoid_doc_model})
      expect(rr.mongoid_doc_model).to eq(mongoid_doc_model)
    end

    it "sets #request" do
      request = double("request")
      rr = subject.new(request)
      expect(rr.request).to eq(request)
    end

    it "sets #response" do
      response = double("response")
      rr = subject.new(nil, response)
      expect(rr.response).to eq(response)
    end

    it "sets #redis_record to be RedisRecord" do
      redis_record = double("redis_record")
      rr = subject.new(nil, nil, {redis_connection: redis_record})
      expect(rr.redis_record).to eq(RequestResponseStats::RedisRecord)
    end

    it "sets .redis on RedisRecord" do
      redis_record = double("redis_record")
      rr = subject.new(nil, nil, {redis_connection: redis_record})
      expect(rr.redis_record.redis).to eq(redis_record)
    end

    it "sets .group_stats_by_time_duration on RedisRecord" do
      redis_record = double("redis_record")
      rr = subject.new(nil, nil, {redis_connection: redis_record})
      expect(rr.redis_record.group_stats_by_time_duration).to eq(60.seconds)
    end
  end

  context "#capture_request_response_cycle_start_info" do
    before(:each) do
      @redis_record = double("redis_record")
      @rrs = subject.new(
        RequestResponseStats::DummyRequest.new({method: "fake_method_name", path: "fake_url"}),
        RequestResponseStats::DummyResponse.new,
        {redis_connection: @redis_record, gather_stats: true}
      )
      @must_present_keys_in_value = %w(req_object_id res_object_id server_name req_path req_http_verb req_time req_url req_format req_controller req_action remote_ip gc_stat)
      @must_present_values_in_value = %w(some_server_name fake_url fake_method_name some_url external_controller external_action some_ip)
    end

    it "sets a new redis key and returns its name" do
      key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      allow(@redis_record).to receive(:set).with(a_string_matching(key_pattern), any_args)
      key_name = @rrs.capture_request_response_cycle_start_info
      expect(key_name).to match(key_pattern)
    end

    it "these keys are present: #{@must_present_keys_in_value.try(:join, ",")}" do
      puts "Must be present keys in value: #{@must_present_keys_in_value.join(",")}"
      key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      value_pattern = /#{@must_present_keys_in_value.join(".*")}/
      allow(@redis_record).to receive(:set).with(a_string_matching(key_pattern), a_string_matching(value_pattern), kind_of(Hash))
      key_name = @rrs.capture_request_response_cycle_start_info
      expect(key_name).to match(key_pattern)
    end

    it "these values are present: #{@must_present_values_in_value.try(:join, ",")}" do
      puts "Must be present values in value: #{@must_present_values_in_value.join(",")}"
      key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      value_pattern = /#{@must_present_values_in_value.join(".*")}/
      allow(@redis_record).to receive(:set).with(a_string_matching(key_pattern), a_string_matching(value_pattern), kind_of(Hash))
      key_name = @rrs.capture_request_response_cycle_start_info
      expect(key_name).to match(key_pattern)
    end
  end

  context "#capture_request_response_cycle_end_info" do
    before(:each) do
      @redis_record = double("redis_record")
      @rrs = subject.new(
        RequestResponseStats::DummyRequest.new({method: "some_method_name", path: "some_dummy_url"}),
        RequestResponseStats::DummyResponse.new,
        {redis_connection: @redis_record, gather_stats: true}
      )
      @current_time = Time.now
      @dummy_req_return_value = {
        req_object_id: "fake_req_obj_id",
        res_object_id: "fake_res_obj_id",
        server_name: ("fake_server_name"),
        req_path: ("fake_path"),
        req_http_verb: ("fake_http_verb"),
        req_time: @current_time.to_i,
        req_url: ("fake_url"),
        req_format: ("fake_format"),
        req_controller: ("fake_controller"),
        req_action: ("fake_action"),
        remote_ip: ("fake_ip"),
        gc_stat: @rrs.send(:get_gc_stat),
      }
      @dummy_req_res_return_value = {
        key_name: nil,
        server_name: "fake_server_name",
        api_name: "fake_api_name",
        api_verb: "fake_http_verb",
        api_controller: "fake_controller",
        api_action: "fake_action",
        request_count: 5,
        min_time: 1,
        max_time: 10,
        avg_time: 5,
        start_time: "some_fake_start_time",
        end_time: "some_fake_end_time",
        error_count: 0,
        min_used_memory_MB: 100,
        max_used_memory_MB: 200,
        avg_used_memory_MB: 150,
        min_swap_memory_MB: 10,
        max_swap_memory_MB: 20,
        avg_swap_memory_MB: 15,
        avg_gc_stat_diff: Hash.new(0),
        min_gc_stat_diff: {},
        max_gc_stat_diff: {},
      }
    end

    it "(new request-response key) sets a new redis key for request-response cycle and returns its name" do
      get_req_key_pattern = /^api_req_res_SUPPORT/
      get_set_req_key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      get_set_res_key_pattern = /^api_req_res_PUBLIC/

      # allow getting and setting of non-requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_req_key_pattern))  # first in position, so that its behavior can be selectively overridden
      allow(@redis_record).to receive(:set).with(a_string_matching(get_req_key_pattern), any_args)

      # allow getting (with return value) and deletion of requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_req_key_pattern)).and_return(@dummy_req_return_value.to_json)
      allow(@redis_record).to receive(:del).with(a_string_matching(get_set_req_key_pattern))

      # looking into the final request-response key
      # when this key doesn't exist already
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_res_key_pattern)).and_return("{}")
      expect(@redis_record).to receive(:set).with(a_string_matching(get_set_res_key_pattern), any_args).and_return("OK")
      key_name = @rrs.capture_request_response_cycle_end_info
      expect(key_name).to match(get_set_res_key_pattern)
    end

    it "(new request-response key) required keys are present" do
      get_req_key_pattern = /^api_req_res_SUPPORT/
      get_set_req_key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      get_set_res_key_pattern = /^api_req_res_PUBLIC/

      # allow getting and setting of non-requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_req_key_pattern))  # first in position, so that its behavior can be selectively overridden
      allow(@redis_record).to receive(:set).with(a_string_matching(get_req_key_pattern), any_args)

      # allow getting (with return value) and deletion of requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_req_key_pattern)).and_return(@dummy_req_return_value.to_json)
      allow(@redis_record).to receive(:del).with(a_string_matching(get_set_req_key_pattern))

      # looking into the final request-response key
      # when this key doesn't exist already
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_res_key_pattern)).and_return("{}")
      must_present_keys_in_value = %w(key_name server_name api_name api_verb api_controller api_action request_count min_time max_time avg_time start_time end_time error_count min_used_memory_MB max_used_memory_MB avg_used_memory_MB min_swap_memory_MB max_swap_memory_MB avg_swap_memory_MB avg_gc_stat_diff min_gc_stat_diff max_gc_stat_diff)
      puts "Must be present keys in value: #{must_present_keys_in_value.join(",")}"
      value_pattern = /#{must_present_keys_in_value.join(".*")}/
      expect(@redis_record).to receive(:set).with(a_string_matching(get_set_res_key_pattern), a_string_matching(value_pattern), kind_of(Hash)).and_return("OK")
      key_name = @rrs.capture_request_response_cycle_end_info
      expect(key_name).to match(get_set_res_key_pattern)
    end

    it "(new request-response key) required values are present" do
      get_req_key_pattern = /^api_req_res_SUPPORT/
      get_set_req_key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      get_set_res_key_pattern = /^api_req_res_PUBLIC/

      # allow getting and setting of non-requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_req_key_pattern))  # first in position, so that its behavior can be selectively overridden
      allow(@redis_record).to receive(:set).with(a_string_matching(get_req_key_pattern), any_args)

      # allow getting (with return value) and deletion of requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_req_key_pattern)).and_return(@dummy_req_return_value.to_json)
      allow(@redis_record).to receive(:del).with(a_string_matching(get_set_req_key_pattern))

      # looking into the final request-response key
      # when this key doesn't exist already
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_res_key_pattern)).and_return("{}")
      must_present_values_in_value = %w(fake_path fake_http_verb fake_controller fake_action)
      puts "Must be present values in value: #{must_present_values_in_value.join(",")}"
      value_pattern = /#{must_present_values_in_value.join(".*")}/
      expect(@redis_record).to receive(:set).with(a_string_matching(get_set_res_key_pattern), a_string_matching(value_pattern), kind_of(Hash)).and_return("OK")
      key_name = @rrs.capture_request_response_cycle_end_info
      expect(key_name).to match(get_set_res_key_pattern)
    end

    it "(existing request-response key): update existing redis key for request-response cycle and returns its name" do
      get_req_key_pattern = /^api_req_res_SUPPORT/
      get_set_req_key_pattern = /^api_req_res_SUPPORT.*REQ_OBJ.*/
      get_set_res_key_pattern = /^api_req_res_PUBLIC/

      # allow getting and setting of non-requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_req_key_pattern))  # first in position, so that its behavior can be selectively overridden
      allow(@redis_record).to receive(:set).with(a_string_matching(get_req_key_pattern), any_args)

      # allow getting (with return value) and deletion of requirement support keys
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_req_key_pattern)).and_return(@dummy_req_return_value.to_json)
      allow(@redis_record).to receive(:del).with(a_string_matching(get_set_req_key_pattern))

      # looking into the final request-response key
      # when this key doesn't exist already
      # Note: Currently for data, just increased value of :request_count is being checked
      allow(@redis_record).to receive(:get).with(a_string_matching(get_set_res_key_pattern)).and_return(@dummy_req_res_return_value.to_json)
      value_pattern = /"request_count":#{@dummy_req_res_return_value[:request_count] + 1}/
      expect(@redis_record).to receive(:set).with(a_string_matching(get_set_res_key_pattern), a_string_matching(value_pattern), kind_of(Hash)).and_return("OK")
      key_name = @rrs.capture_request_response_cycle_end_info
      expect(key_name).to match(get_set_res_key_pattern)
    end
  end

  context "#capture_request_response_cycle_error_info" do
    it "calls capture_request_response_cycle_end_info with {capture_error: true}" do
      @redis_record = double("redis_record")
      @rrs = subject.new(
        RequestResponseStats::DummyRequest.new({method: "some_method_name", path: "some_dummy_url"}),
        RequestResponseStats::DummyResponse.new,
        {redis_connection: @redis_record, gather_stats: true}
      )
      @current_time = Time.now
      allow_any_instance_of(subject).to receive(:capture_request_response_cycle_end_info).with({capture_error: true}).and_return("success")
      expect(@rrs.capture_request_response_cycle_error_info).to eq("success")
    end
  end

  context "#move_data_from_redis_to_mongo" do
    before(:each) do
      redis_record = double("redis_record")
      mongoid_doc_model = double("mongoid_doc_model")
      @rrs = subject.new(
        RequestResponseStats::DummyRequest.new({method: "some_method_name", path: "some_dummy_url"}),
        RequestResponseStats::DummyResponse.new,
        {redis_connection: redis_record, mongoid_doc_model: mongoid_doc_model, gather_stats: true}
      )
      allow(redis_record).to receive(:keys).and_return(
        "api_req_res_PUBLIC_key1",
        "api_req_res_key2",
        "key3",
        "key4_api_req_res",
        "api_req_res_PUBLIC_key5",
        "api_req_res_PUBLIC_key6",
        "some_key7"
      )
      allow(RequestResponseStats::RedisRecord).to receive(:formatted_parsed_get_for_mongo).with("api_req_res_PUBLIC_key1").and_return("key1_value")
      allow(RequestResponseStats::RedisRecord).to receive(:formatted_parsed_get_for_mongo).with("api_req_res_PUBLIC_key5").and_return("key5_value")
      allow(RequestResponseStats::RedisRecord).to receive(:formatted_parsed_get_for_mongo).with("api_req_res_PUBLIC_key6").and_return("key6_value")
      allow(RequestResponseStats::RedisRecord).to receive(:freezed_keys).with(no_args).and_return(["api_req_res_PUBLIC_key1", "api_req_res_PUBLIC_key5"])
      expect(@rrs.mongoid_doc_model).to receive(:create).with(any_args).and_return("success").exactly(2).times
      expect(@rrs.redis_record).to receive(:del).with("api_req_res_PUBLIC_key1").and_return("success")
      expect(@rrs.redis_record).to receive(:del).with("api_req_res_PUBLIC_key5").and_return("success")
    end

    it %Q(
    moves only request-response PUBLIC keys
    moves only freezed keys
    uses value as formatted by RedisRecord.formatted_parsed_get_for_mongo to feed mongo
    deletes the moved key from redis
    ) do
      expect(@rrs.move_data_from_redis_to_mongo).to eq(2)
    end
  end
end
