# File: app/controllers/req_res_stat_controller.rb

# TODO: This controller is yet to be tested
class ReqResStatController < ApplicationController

  # params[:start_time] format: "2009-06-24 12:39:54 +09:00"
  # params[:end_time] format: "2009-06-24 12:39:54 +09:00"
  # params[:stat_key] popular choices: "request_count", "error_count", "min_time", "max_time", "avg_time"
  def get_stats
    stat_key = params[:stat_key].to_sym
    start_time = parse_date_time_zone params[:start_time]
    end_time = parse_date_time_zone params[:end_time]
    granularity_in_hours = params[:granularity_in_hours].to_i.hours if params[:granularity_in_hours].present?

    min_values = ReqResStat.get_min(stat_key, start_time, end_time, granularity_in_hours)
    max_values = ReqResStat.get_max(stat_key, start_time, end_time, granularity_in_hours)
    avg_values = ReqResStat.get_avg(stat_key, start_time, end_time, granularity_in_hours)

    return_value = {
      start_time: start_time,
      end_time: end_time,
      granularity_in_hours: granularity_in_hours,
      min_values: min_values,
      max_values: max_values,
      avg_values: avg_values,
    }

    render json: return_value

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

  # time format: "2009-06-24 12:39:54 +09:00"
  def parse_date_time_zone(date_time_zone)
    date, time, zone = date_time_zone.split(" ")
    date = date.split("-")
    time = time.split(":")

    Time.new(*date, *time, zone)
  end
end

