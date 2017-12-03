require "spec_helper"

RSpec.describe RequestResponseStats::RequestResponse do
  subject { RequestResponseStats::RequestResponse }

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
  end

  context "#capture_request_response_cycle_end_info" do
  end

  context "#capture_request_response_cycle_error_info" do
  end

  context "#move_data_from_redis_to_mongo" do
  end
end
