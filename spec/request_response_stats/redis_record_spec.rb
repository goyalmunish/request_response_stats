require "spec_helper"

RSpec.describe RequestResponseStats::RedisRecord do
  subject { RequestResponseStats::RedisRecord }

  it "defines REDIS_RR_KEY_NAMESPACE" do
    expect(subject::REDIS_RR_KEY_NAMESPACE).not_to be nil
  end

  it "defines PERMITTED_KEYS as an Array of string keys permitted to be captured" do
    expect(subject::PERMITTED_KEYS).not_to be nil
    expect(subject::PERMITTED_KEYS).to be_a_kind_of(Array)
  end

  it "defines ALERT_THRESHOLD as a Hash with threshold limits as values" do
    expect(subject::ALERT_THRESHOLD).not_to be nil
    expect(subject::ALERT_THRESHOLD).to be_a_kind_of(Hash)
  end

  context ".redis" do
    it "raises error as a reminder to override" do
      expect{subject.redis}.to raise_error(StandardError, "UNDEFINED redis")
    end
  end

  context ".get" do
    it "delegates to underneath redis connection" do
      redis = double("redis")
      allow(redis).to receive(:get).with("some_key_name").and_return("some_value")

      subject.define_singleton_method(:redis) { redis }
      expect(subject.get("some_key_name")).to eq("some_value")
    end
  end

  context ".set" do
    it "delegates to underneath redis connection" do
      redis = double("redis")
      allow(redis).to receive("set").with("some_key_name", "some_value", {}).and_return("OK")

      subject.define_singleton_method(:redis) { redis }
      expect(subject.set("some_key_name", "some_value")).to eq("OK")
    end
  end

  context ".del" do
    it "delegates to underneath redis connection" do
      redis = double("redis")
      allow(redis).to receive(:del).with("some_key_name").and_return("OK")

      subject.define_singleton_method(:redis) { redis }
      expect(subject.del("some_key_name")).to eq("OK")
    end
  end

  context ".all_keys" do
    it "returns all PUBLIC redis_record specific redis keys in reverse sorted order" do
      redis = double("redis")
      allow(redis).to receive(:keys).and_return(["a", "b", "c", "#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"])

      subject.define_singleton_method(:redis) { redis }
      expect(subject.all_keys).to eq(["#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"])
    end

    it "returns all redis_record specific redis keys in reverse sorted order if support option is true" do
      redis = double("redis")
      allow(redis).to receive(:keys).and_return(["a", "b", "c", "#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"])

      subject.define_singleton_method(:redis) { redis }
      expect(subject.all_keys({support: true})).to eq(["#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2", "#{subject::REDIS_RR_KEY_NAMESPACE}_1"])
    end
  end

  context ".parsed_get" do
    it "delegates to underneath redis connection" do
      redis = double("redis")
      allow(redis).to receive(:get).with("some_key_name").and_return("{\"first_name\":\"Munish\",\"last_name\":\"Goyal\"}")

      subject.define_singleton_method(:redis) { redis }
      expect(subject.parsed_get("some_key_name")).to eq({"first_name" => "Munish", "last_name" => "Goyal"})
    end
  end

  context ".formatted_parsed_get_for_mongo" do
    it "formats the parsed data for mongo feed" do
      parsed_data = {
        "key_name"=>"api_req_res_PUBLIC_Munishs-MacBook-Pro.local_some_endpoint_GET_2017-04-16-0100",
        "server_name"=>"Munishs-MacBook-Pro.local",
        "api_name"=>"some_endpoint",
        "api_verb"=>"GET",
        "api_controller"=>"some_controller",
        "api_action"=>"some_action",
        "request_count"=>2,
        "min_time"=>0.03,
        "max_time"=>0.05,
        "avg_time"=>0.04,
        "start_time"=>"2017-04-15 01:40:00 UTC",
        "end_time"=>"2017-04-15 01:41:00 UTC",
        "error_count"=>0,
        "min_used_memory_MB"=>0,
        "max_used_memory_MB"=>0,
        "avg_used_memory_MB"=>0,
        "min_swap_memory_MB"=>0,
        "max_swap_memory_MB"=>0,
        "avg_swap_memory_MB"=>0
      }
      parsed_data_copy = JSON.parse(parsed_data.to_json)
      allow(subject).to receive(:parsed_get).with("some_key_name").and_return(parsed_data_copy)
      formatted_parsed_data = subject.formatted_parsed_get_for_mongo("some_key_name")
      expect(formatted_parsed_data.keys).to eq(parsed_data.keys)
      expect((formatted_parsed_data.values - parsed_data.values).map(&:to_s)).to eq(["2017-04-15T01:40:00+00:00", "2017-04-15T01:41:00+00:00"])
      expect((parsed_data.values - formatted_parsed_data.values).map(&:to_s)).to eq(["2017-04-15 01:40:00 UTC", "2017-04-15 01:41:00 UTC"])
    end
  end

  context ".hashify_all_data" do
    it "returns all PUBLIC redis_record specific redis keys in reverse sorted order" do
      redis = double("redis")
      temp_keys = ["a", "b", "c", "#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      used_temp_keys = ["#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      allow(redis).to receive(:keys).and_return(temp_keys)
      used_temp_keys.each do |used_temp_key|
        allow(redis).to receive(:get).with(used_temp_key).and_return("{\"first_name\":\"Munish\",\"last_name\":\"Goyal\"}")
      end

      subject.define_singleton_method(:redis) { redis }
      expect(subject.hashify_all_data).to eq({
        "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2" => {"first_name"=>"Munish", "last_name"=>"Goyal"}
      })
    end

    it "returns all redis_record specific redis keys in reverse sorted order if support option is true" do
      redis = double("redis")
      temp_keys = ["a", "b", "c", "#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      used_temp_keys = ["#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      allow(redis).to receive(:keys).and_return(temp_keys)
      used_temp_keys.each do |used_temp_key|
        allow(redis).to receive(:get).with(used_temp_key).and_return("{\"first_name\":\"Munish\",\"last_name\":\"Goyal\"}")
      end

      subject.define_singleton_method(:redis) { redis }
      expect(subject.hashify_all_data({support: true})).to eq({
        "#{subject::REDIS_RR_KEY_NAMESPACE}_1" => {"first_name"=>"Munish", "last_name"=>"Goyal"},
        "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2" => {"first_name"=>"Munish", "last_name"=>"Goyal"}
      })
    end
  end

  context ".flush_all_keys" do
    it "delegates to underneath redis connection to delete all redis_record specific keys" do
      redis = double("redis")
      temp_keys = ["a", "b", "c", "#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      used_temp_keys = ["#{subject::REDIS_RR_KEY_NAMESPACE}_1", "#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC_2"]
      allow(redis).to receive(:keys).and_return(temp_keys)
      allow(redis).to receive(:del).with(*used_temp_keys.sort.reverse).and_return("OK")

      subject.define_singleton_method(:redis) { redis }
      expect(subject.flush_all_keys).to eq("OK")
    end
  end

  context ".group_stats_by_time_duration" do
    it "raises error as a reminder to override" do
      expect{subject.group_stats_by_time_duration}.to raise_error(StandardError, "UNDEFINED group_stats_by_time_duration")
    end
  end

  context ".support_key" do
    it "returns name of support key for given server_name and key_name" do
      server_name = "some_server_name"
      key_name = "some_key_name"
      expect(subject.support_key(server_name, key_name))
        .to eq("api_req_res_SUPPORT_some_server_name_some_key_name")
        # .to match(/#{subject::REDIS_RR_KEY_NAMESPACE}_SUPPORT/)
        # .and match(/#{server_name}/)
        # .and match(/#{key_name}/)
    end

    it "uses 'default' as default key_name" do
      server_name = "some_server_name"
      expect(subject.support_key(server_name))
        .to eq("api_req_res_SUPPORT_some_server_name_default")
        # .to match(/#{server_name}/)
        # .and match(/default/)
    end
  end

  context ".req_key" do
    it "returns name of request key for given server_name and req_object_id" do
      server_name = "some_server_name"
      req_object_id = "some_req_object_id"
      expect(subject.req_key(server_name, req_object_id))
        .to eq("api_req_res_SUPPORT_some_server_name_REQ_OBJ_some_req_object_id")
        # .to match(/#{subject::REDIS_RR_KEY_NAMESPACE}_SUPPORT/)
        # .and match(/#{server_name}/)
        # .and match(/REQ_OBJ/)
        # .and match(/#{req_object_id}/)
    end
  end

  context ".req_res_key" do
    it "raises error if group_stats_by_time_duration is not re-defined" do
      server_name = "some_server_name"
      api_name = "some_api_name"
      http_verb = "some_http_verb"
      expect{subject.req_res_key(server_name, api_name, http_verb)}.to raise_error(StandardError, "UNDEFINED group_stats_by_time_duration")
    end

    it "returns name of request key for given server_name and key_name" do
      server_name = "some_server_name"
      api_name = "some_api_name"
      http_verb = "some_http_verb"

      subject.define_singleton_method(:group_stats_by_time_duration) { 1.minute }

      t = Time.utc(2017, 06, 26, 23, 59, 59)
      allow(Time).to receive(:now).and_return(t)

      expect(subject.req_res_key(server_name, api_name, http_verb))
        .to eq("api_req_res_PUBLIC_some_server_name_some_api_name_some_http_verb_2017-06-26-1439")
        # .to match(/#{subject::REDIS_RR_KEY_NAMESPACE}_PUBLIC/)
        # .and match(/#{server_name}/)
        # .and match(/#{api_name}/)
        # .and match(/#{http_verb}/)

      subject.define_singleton_method(:group_stats_by_time_duration) { 6.hours }

      expect(subject.req_res_key(server_name, api_name, http_verb))
        .to eq("api_req_res_PUBLIC_some_server_name_some_api_name_some_http_verb_2017-06-26-3")
    end
  end

  context ".get_slot_range_for_key" do
    it "returns name of request key for given server_name and key_name" do
      redis_key = "api_req_res_PUBLIC_some_server_name_some_api_name_some_http_verb_2017-06-26-1439"
      subject.define_singleton_method(:group_stats_by_time_duration) { 1.minute }
      expect(subject.get_slot_range_for_key(redis_key).map(&:to_s))
        .to eq(["2017-06-26 23:59:00 UTC", "2017-06-27 00:00:00 UTC"])

      redis_key = "api_req_res_PUBLIC_some_server_name_some_api_name_some_http_verb_2017-06-26-3"
      subject.define_singleton_method(:group_stats_by_time_duration) { 6.hours }
      expect(subject.get_slot_range_for_key(redis_key).map(&:to_s))
        .to eq(["2017-06-26 18:00:00 UTC", "2017-06-27 00:00:00 UTC"])
    end
  end

  context ".jsonified_set" do
    before(:each) {
      @key = "some_key_name"
      @value = {
        "key_name"=>"api_req_res_PUBLIC_Munishs-MacBook-Pro.local_some_endpoint_GET_2017-04-16-0100",
        "server_name"=>"Munishs-MacBook-Pro.local",
        "api_name"=>"some_endpoint",
        "api_verb"=>"GET",
        "api_controller"=>"some_controller",
        "api_action"=>"some_action",
        "request_count"=>2,
        "min_time"=>0.03,
        "max_time"=>0.05,
        "avg_time"=>0.04,
        "start_time"=>"2017-04-15 01:40:00 UTC",
        "end_time"=>"2017-04-15 01:41:00 UTC",
        "error_count"=>0,
        # "some_non_permitted_key"=> "some_fake_value",
      }

      redis = double("redis")
      subject.define_singleton_method(:redis) { redis }
    }

    it "sets jsonified hash value (from only the permitted keys) to redis" do
      allow(subject.redis).to receive(:set).with(@key, @value.to_json, any_args).and_return("OK")
      subject.jsonified_set(@key, @value)
    end

    it "non-permitted keys are removed if strict_key_check is true" do
      @value["some_non_permitted_key"] = "some_fake_value"
      value_with_only_permitted_keys = JSON.parse(@value.to_json).select!{|k,v| subject::PERMITTED_KEYS.include? k.to_s}
      allow(subject.redis).to receive(:set).with(@key, value_with_only_permitted_keys.to_json, {}).and_return("OK")
      subject.jsonified_set(@key, @value, {}, {strict_key_check: true})
    end

    it "by default strict_key_check is true" do
      @value["some_non_permitted_key"] = "some_fake_value"
      value_with_only_permitted_keys = JSON.parse(@value.to_json).select!{|k,v| subject::PERMITTED_KEYS.include? k.to_s}
      allow(subject.redis).to receive(:set).with(@key, value_with_only_permitted_keys.to_json, {}).and_return("OK")
      subject.jsonified_set(@key, @value, {})
    end

    it "non-permitted keys are present if strick_key_check is false" do
      @value["some_non_permitted_key"] = "some_fake_value"
      allow(subject.redis).to receive(:set).with(@key, @value.to_json, {}).and_return("OK")
      subject.jsonified_set(@key, @value, {}, {strict_key_check: false})
    end

    it "raises alert if thresholds are breached" do
      @value["max_time"] = 300  # setting max_time to 300 seconds
      allow(subject.redis).to receive(:set).with(@key, @value.to_json, {}).and_return("OK")
      expect(subject).to receive(:raise_alert).with(any_args)
      subject.jsonified_set(@key, @value, {}, {strict_key_check: false})
    end
  end

  context ".freezed_keys" do
    it "returns only the freezed keys; freezed status depends upon `is_key_freezed?` outcome" do
      allow(subject).to receive(:all_keys).and_return(["key1", "key2"])
      allow_any_instance_of(subject).to receive(:is_key_freezed?).and_return(true)
      expect(subject.freezed_keys).to eq(["key1", "key2"])
      allow_any_instance_of(subject).to receive(:is_key_freezed?).and_return(false)
      expect(subject.freezed_keys).to eq([])
    end
  end

  context "#key" do
    it "returns key" do
      key_name = "some_key"
      expect(subject.new(key_name, "some_value").key).to eq(key_name)
    end
  end

  context "#value" do
    it "returns value" do
      value_name = "some_value"
      expect(subject.new("some_key", value_name).value).to eq(value_name)
    end
  end

  context "#is_key_freezed?" do
    it "returns if a key is freezed: that is, the key will no longer be updated and hence can be moved" do
      # allow(subject).to receive(:group_stats_by_time_duration).and_return(1.hour)
      redis_key = "api_req_res_PUBLIC_some_server_name_some_api_name_some_http_verb_2017-06-26-1439"
      subject.define_singleton_method(:group_stats_by_time_duration) { 1.minute }
      allow(Time).to receive(:now).and_return(Time.new(2017, 06, 26, 23, 59, 00, "+00:00"))
      expect(subject.new(redis_key).is_key_freezed?).to be false
      allow(Time).to receive(:now).and_return(Time.new(2017, 06, 27, 00, 00, 00, "+00:00"))
      expect(subject.new(redis_key).is_key_freezed?).to be false
      allow(Time).to receive(:now).and_return(Time.new(2017, 06, 27, 00, 00, 01, "+00:00" ))
      expect(subject.new(redis_key).is_key_freezed?).to be true
    end
  end

end
