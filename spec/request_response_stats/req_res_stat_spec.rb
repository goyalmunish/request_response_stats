require "spec_helper"

RSpec.describe RequestResponseStats::ReqResStat do
  subject { RequestResponseStats::ReqResStat }

  before(:all) do
    mongoid_config_path = File.expand_path(File.dirname(__FILE__) + "/mongoid_example.yml")
    # Note: Make sure that the configuration is correct at `mongoid_config_path`
    Mongoid.load!(mongoid_config_path, :development)
  end

  before(:each) do
    @dummy_input_value = {
      "key_name"=>"api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET_2017-06-27-0611",
      "server_name"=>"Munishs-MacBook-Pro.local",
      "api_name"=>"/api/web/v7/customers/all_customers",
      "api_verb"=>"GET",
      "api_controller"=>"api/web/v7/customers",
      "api_action"=>"index",
      "request_count"=>1,
      "min_time"=>1.891,
      "max_time"=>1.891,
      "avg_time"=>1.891,
      "start_time"=>Time.new(2017, 01, 01, 00, 00, 00, "+00:00"),
      "end_time"=>Time.new(2017, 01, 01, 00, 01, 00, "+00:00"),
      "error_count"=>0,
      "min_used_memory_MB"=>0,
      "max_used_memory_MB"=>0,
      "avg_used_memory_MB"=>0,
      "min_swap_memory_MB"=>0,
      "max_swap_memory_MB"=>0,
      "avg_swap_memory_MB"=>0,
      "avg_gc_stat_diff"=>{
        "count"=>2,
        "heap_allocated_pages"=>0,
        "heap_sorted_length"=>0,
        "heap_allocatable_pages"=>0,
        "heap_available_slots"=>0,
        "heap_live_slots"=>717,
        "heap_free_slots"=>-717,
        "heap_final_slots"=>0,
        "heap_marked_slots"=>48882,
        "heap_swept_slots"=>118536,
        "heap_eden_pages"=>0,
        "heap_tomb_pages"=>0,
        "total_allocated_pages"=>0,
        "total_freed_pages"=>0,
        "total_allocated_objects"=>543300,
        "total_freed_objects"=>542583,
        "malloc_increase_bytes"=>-567824,
        "malloc_increase_bytes_limit"=>0,
        "minor_gc_count"=>2,
        "major_gc_count"=>0,
        "remembered_wb_unprotected_objects"=>2798,
        "remembered_wb_unprotected_objects_limit"=>0,
        "old_objects"=>29874,
        "old_objects_limit"=>0,
        "oldmalloc_increase_bytes"=>4237104,
        "oldmalloc_increase_bytes_limit"=>0
      },
      "min_gc_stat_diff"=>{
        "count"=>2,
        "heap_allocated_pages"=>0,
        "heap_sorted_length"=>0,
        "heap_allocatable_pages"=>0,
        "heap_available_slots"=>0,
        "heap_live_slots"=>717,
        "heap_free_slots"=>-717,
        "heap_final_slots"=>0,
        "heap_marked_slots"=>48882,
        "heap_swept_slots"=>118536,
        "heap_eden_pages"=>0,
        "heap_tomb_pages"=>0,
        "total_allocated_pages"=>0,
        "total_freed_pages"=>0,
        "total_allocated_objects"=>543300,
        "total_freed_objects"=>542583,
        "malloc_increase_bytes"=>-567824,
        "malloc_increase_bytes_limit"=>0,
        "minor_gc_count"=>2,
        "major_gc_count"=>0,
        "remembered_wb_unprotected_objects"=>2798,
        "remembered_wb_unprotected_objects_limit"=>0,
        "old_objects"=>29874,
        "old_objects_limit"=>0,
        "oldmalloc_increase_bytes"=>4237104,
        "oldmalloc_increase_bytes_limit"=>0
      },
      "max_gc_stat_diff"=>{
        "count"=>2,
        "heap_allocated_pages"=>0,
        "heap_sorted_length"=>0,
        "heap_allocatable_pages"=>0,
        "heap_available_slots"=>0,
        "heap_live_slots"=>717,
        "heap_free_slots"=>-717,
        "heap_final_slots"=>0,
        "heap_marked_slots"=>48882,
        "heap_swept_slots"=>118536,
        "heap_eden_pages"=>0,
        "heap_tomb_pages"=>0,
        "total_allocated_pages"=>0,
        "total_freed_pages"=>0,
        "total_allocated_objects"=>543300,
        "total_freed_objects"=>542583,
        "malloc_increase_bytes"=>-567824,
        "malloc_increase_bytes_limit"=>0,
        "minor_gc_count"=>2,
        "major_gc_count"=>0,
        "remembered_wb_unprotected_objects"=>2798,
        "remembered_wb_unprotected_objects_limit"=>0,
        "old_objects"=>29874,
        "old_objects_limit"=>0,
        "oldmalloc_increase_bytes"=>4237104,
        "oldmalloc_increase_bytes_limit"=>0
      }
    }
    subject.destroy_all
    @time = Time.new(2017, 01, 01, 00, 01, 00, "+00:00")
    rec_value_01 = @dummy_input_value.clone
    rec_value_01["key_name"] = "record_01"
    rec_value_01["start_time"] = @time
    rec_value_01["end_time"] = @time + 1.minute
    rec_value_01["max_time"] = 10
    rec_value_02 = @dummy_input_value.clone
    rec_value_02["key_name"] = "record_02"
    rec_value_02["start_time"] = @time + 1.hour
    rec_value_02["end_time"] = @time + 1.hour + 1.minute
    rec_value_02["max_time"] = 20
    rec_value_03 = @dummy_input_value.clone
    rec_value_03["key_name"] = "record_03"
    rec_value_03["start_time"] = @time + 2.hour
    rec_value_03["end_time"] = @time + 2.hour + 1.minute
    rec_value_03["max_time"] = 30
    @record_01 = subject.create(rec_value_01)
    @record_02 = subject.create(rec_value_02)
    @record_03 = subject.create(rec_value_03)
  end

  it "defines DEFAULT_STATS_GRANULARITY as an ActiveSupport::Duration" do
    expect(subject::DEFAULT_STATS_GRANULARITY).not_to be nil
    expect(subject::DEFAULT_STATS_GRANULARITY).to be_a_kind_of(ActiveSupport::Duration)
  end

  it "defines PERCISION as in Integer value" do
    expect(subject::PERCISION).not_to be nil
    expect(subject::PERCISION).to be_a_kind_of(Integer)
  end

  context ".get_within" do
    it "returns records within :start_time (first arg) and :end_time (second arg)" do
      # require 'byebug'; byebug
      expect(subject.get_within(@time, @time + 61.seconds).size).to eq(1)
      expect(subject.get_within(@time, @time + 62.minute).size).to eq(2)
      expect(subject.get_within(@time, @time + 122.hours).size).to eq(3)
    end
    it "ignores :start_time (first arg) and :end_time (second arg) if both are nil, and returns the same collection" do
      expect(subject.get_within(nil, nil).size).to eq(3)
    end
  end

  context ".get_sum" do
    it "returns sum value of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) records at given granularity level" do
      expect(subject.get_sum("max_time", @time, @time + 6.hours, 1.hour).map{|r| r[:data]}).to eq([10.0, 20.0, 30.0, 0, 0, 0])
      expect(subject.get_sum("max_time", @time, @time + 6.hours, 3.hour).map{|r| r[:data]}).to eq([60.0, 0])
      expect(subject.get_sum("max_time", @time, @time + 6.hours, 6.hour).map{|r| r[:data]}).to eq([60.0])
      expect(subject.get_sum("max_time", @time, @time + 2.hours, 3.hour).map{|r| r[:data]}).to eq([30.0])
    end
  end

  context ".get_min" do
    it "returns minimum value of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) records at given granularity level" do
      # require 'byebug'; byebug
      expect(subject.get_min("max_time", @time, @time + 6.hours, 1.hour).map{|r| r[:data]}).to eq([10.0, 20.0, 30.0, nil, nil, nil])
      expect(subject.get_min("max_time", @time, @time + 6.hours, 3.hour).map{|r| r[:data]}).to eq([10.0, nil])
      expect(subject.get_min("max_time", @time, @time + 6.hours, 6.hour).map{|r| r[:data]}).to eq([10.0])
      expect(subject.get_min("max_time", @time, @time + 2.hours, 3.hour).map{|r| r[:data]}).to eq([10.0])
    end
  end

  context ".get_max" do
    it "returns maximum value of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) records at given granularity level" do
      expect(subject.get_max("max_time", @time, @time + 6.hours, 1.hour).map{|r| r[:data]}).to eq([10.0, 20.0, 30.0, nil, nil, nil])
      expect(subject.get_max("max_time", @time, @time + 6.hours, 3.hour).map{|r| r[:data]}).to eq([30.0, nil])
      expect(subject.get_max("max_time", @time, @time + 6.hours, 6.hour).map{|r| r[:data]}).to eq([30.0])
      expect(subject.get_max("max_time", @time, @time + 2.hours, 3.hour).map{|r| r[:data]}).to eq([20.0])
    end
  end

  context ".get_avg" do
    it "returns average value of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) records at given granularity level" do
      expect(subject.get_avg("max_time", @time, @time + 6.hours, 1.hour).map{|r| r[:data]}).to eq([10.0, 20.0, 30.0, 0, 0, 0])
      expect(subject.get_avg("max_time", @time, @time + 6.hours, 3.hour).map{|r| r[:data]}).to eq([20.0, 0])
      expect(subject.get_avg("max_time", @time, @time + 6.hours, 6.hour).map{|r| r[:data]}).to eq([20.0])
      expect(subject.get_avg("max_time", @time, @time + 2.hours, 3.hour).map{|r| r[:data]}).to eq([15.0])
    end
  end

  context ".get_details" do
    it "returns details of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) for :sum, for records at given granularity level" do
      data = subject.get_details("max_time", @time, @time + 6.hours, :sum, 2.hour)
      expect(data.size).to eq(3)
      expect(data[0]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>2,
              :data=>30.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 00, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 02, 01, 00, "+00:00")
        }
      )
      expect(data[1]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>1,
              :data=>30.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 02, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 04, 01, 00, "+00:00")
        }
      )
      expect(data[2]).to eq(
        {
          :data=>[],
          :start_time=> Time.new(2017, 01, 01, 04, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 06, 01, 00, "+00:00")
        }
      )
    end

    it "returns details of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) for :avg, for records at given granularity level" do
      data = subject.get_details("max_time", @time, @time + 6.hours, :avg, 2.hour)
      expect(data.size).to eq(3)
      expect(data[0]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>2,
              :data=>15.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 00, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 02, 01, 00, "+00:00")
        }
      )
      expect(data[1]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>1,
              :data=>30.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 02, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 04, 01, 00, "+00:00")
        }
      )
      expect(data[2]).to eq(
        {
          :data=>[],
          :start_time=> Time.new(2017, 01, 01, 04, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 06, 01, 00, "+00:00")
        }
      )
    end

    it "returns details of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) for :min, for records at given granularity level" do
      data = subject.get_details("max_time", @time, @time + 6.hours, :min, 2.hour)
      expect(data.size).to eq(3)
      expect(data[0]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>2,
              :data=>10.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 00, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 02, 01, 00, "+00:00")
        }
      )
      expect(data[1]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>1,
              :data=>30.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 02, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 04, 01, 00, "+00:00")
        }
      )
      expect(data[2]).to eq(
        {
          :data=>[],
          :start_time=> Time.new(2017, 01, 01, 04, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 06, 01, 00, "+00:00")
        }
      )
    end

    it "returns details of given :key (first arg) within given :start_time (second arg) and :end_time (third arg) for :max, for records at given granularity level" do
      data = subject.get_details("max_time", @time, @time + 6.hours, :max, 2.hour)
      expect(data.size).to eq(3)
      expect(data[0]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>2,
              :data=>20.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 00, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 02, 01, 00, "+00:00")
        }
      )
      expect(data[1]).to eq(
        {
          :data=>[
            {
              :server_plus_api=>"Munishs-MacBook-Pro.local_/api/web/v7/customers/all_customers_GET",
              :count=>1,
              :data=>30.0
            }
          ],
          :start_time=> Time.new(2017, 01, 01, 02, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 04, 01, 00, "+00:00")
        }
      )
      expect(data[2]).to eq(
        {
          :data=>[],
          :start_time=> Time.new(2017, 01, 01, 04, 01, 00, "+00:00"),
          :end_time=>   Time.new(2017, 01, 01, 06, 01, 00, "+00:00")
        }
      )
    end
  end

  context "#server_plus_api" do
    it "returns a string combination of server_name, api_name, and api_verb" do
      record = subject.create(@dummy_input_value)
      expect(record.server_plus_api).to match(record.server_name)
      expect(record.server_plus_api).to match(record.api_name)
      expect(record.server_plus_api).to match(record.api_verb)
    end
  end
end
