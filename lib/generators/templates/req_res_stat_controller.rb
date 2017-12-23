# File: app/controllers/req_res_stat_controller.rb

# TODO: This controller is not fully tested yet
class ReqResStatController < ApplicationController
  # Note: Refer https://www.chartkick.com/ and gems: chartkick for easily creating charts using Ruby

  # params[:start_time] format: "2009-06-24 12:39:54 +09:00"
  # params[:end_time] format: "2009-06-24 12:39:54 +09:00"
  # params[:stat_key] popular choices: "request_count", "error_count", "min_time", "max_time", "avg_time"
  def get_stats
    # query conditions
    start_time = params[:start_time].present? ? parase_data_time_zone(params[:start_time]) : Time.now - 7.days
    end_time = params[:end_time].present? ? parase_data_time_zone(params[:end_time]) : Time.now
    granularity_in_hours = params[:granularity_in_hours].present? ? params[:granularity_in_hours].to_i.hours : 1.hour

    # firing the base query only once
    base_req_res_stats = ReqResStat.get_within(start_time, end_time)

    # gathering data
    @request_count_stats = fetch_stats_for(:request_count, start_time, end_time, granularity_in_hours, base_req_res_stats)
    @max_time_stats = fetch_stats_for(:max_time, start_time, end_time, granularity_in_hours, base_req_res_stats)
    @avg_time_stats = fetch_stats_for(:avg_time, start_time, end_time, granularity_in_hours, base_req_res_stats)
    @min_time_stats = fetch_stats_for(:min_time, start_time, end_time, granularity_in_hours, base_req_res_stats)

    render json: {
      request_count_stats: @request_count_stats,
      max_time_stats: @max_time_stats,
      avg_time_stats: @avg_time_stats,
      min_time_stats: @min_time_stats
    }
  rescue Exception => ex
    error_message = [ex.message, ex.backtrace.join("\n")].join("\n")
    render json: {error_message: error_message}
  end

  def get_details
    stat_key = params[:stat_key].to_sym
    start_time = parse_date_time_zone params[:start_time]
    end_time = parse_date_time_zone params[:end_time]
    granularity_in_hours = params[:granularity_in_hours].to_i.hours if params[:granularity_in_hours].present?

    details = ReqResStat.get_details(stat_key, start_time, end_time, nil, granularity_in_hours)

    return_value = {
      details: details
    }

    render json: return_value
  rescue Exception => ex
    error_message = [ex.message, ex.backtrace.join("\n")].join("\n")
    render json: {error_message: error_message}
  end

  private

  # if `base_records` are passed, then the base_records won't be created using `start_time` and `end_time`,
  # so the values for `start_time` and `end_time` are ignored if `base_records` is present
  def fetch_stats_for(stat_key, start_time, end_time, granularity_in_hours, base_records=nil)
    if base_records
      # use the passed basic dataset
      base_req_res_stats = base_records
    else
      # create the basic dataset
      base_req_res_stats = ReqResStat.get_within(start_time, end_time)
    end

    min_values = line_chart_data base_req_res_stats.get_min(stat_key, start_time, end_time, granularity_in_hours)
    max_values = line_chart_data base_req_res_stats.get_max(stat_key, start_time, end_time, granularity_in_hours)
    avg_values = line_chart_data base_req_res_stats.get_avg(stat_key, start_time, end_time, granularity_in_hours)

    stats_data = [
      {
        name: "Min. Values",
        data: min_values
      },
      {
        name: "Max. Values",
        data: max_values
      },
      {
        name: "Avg. Values",
        data: avg_values
      }
    ]

    data = {
      start_time: start_time,
      end_time: end_time,
      granularity_in_hours: granularity_in_hours,
      stats_data: stats_data
    }

    data
  end

  def line_chart_data(values)
    values_data = {}
    values.each do |elem|
      values_data[elem[:start_time]] = elem[:data] || 0
    end

    values_data
  end

  # time format: "2009-06-24 12:39:54 +09:00"
  def parse_date_time_zone(date_time_zone)
    date, time, zone = date_time_zone.split(" ")
    date = date.split("-")
    time = time.split(":")

    Time.new(*date, *time, zone)
  end
end

