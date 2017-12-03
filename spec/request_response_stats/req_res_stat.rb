require "spec_helper"

RSpec.describe RequestResponseStats::ReqResStat do
  subject { RequestResponseStats::ReqResStat }

  it "defines DEFAULT_STATS_GRANULARITY as an ActiveSupport::Duration" do
    expect(subject::DEFAULT_STATS_GRANULARITY).not_to be nil
    expect(subject::DEFAULT_STATS_GRANULARITY).to be_a_kind_of(ActiveSupport::Duration)
  end

  it "defines PERCISION as in Integer value" do
    expect(subject::PERCISION).not_to be nil
    expect(subject::PERCISION).to be_a_kind_of(Integer)
  end

  context ".get_within" do
  end

  context ".get_sum" do
  end

  context ".get_min" do
  end

  context ".get_max" do
  end

  context ".get_min" do
  end

  context ".get_details" do
  end

  context "#server_plus_api" do
  end
end
