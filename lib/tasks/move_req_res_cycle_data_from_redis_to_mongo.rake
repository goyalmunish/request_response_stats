# File: lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake

require 'request_response_stats'
include RequestResponseStats

desc 'Send request response cycle data from redis to mongo'
namespace :request_response do
  task :move_from_redis_to_mongo => :environment do
    Rails.logger.info "RequestResponseStats: Moving stats data from Redis to Mongo at #{Time.now}."
    rrs = RequestResponse.new(nil, nil)
    count = rrs.move_data_from_redis_to_mongo
    Rails.logger.info "RequestResponseStats: Moved #{count} keys."
  end
end

# Cron example
# Moving data from Redis to Mongo at interval of 15 mins
# 0,15,30,45 * * * * /bin/bash -l -c 'cd /<project_dir> && RAILS_ENV=production bundle exec rake request_response:move_from_redis_to_mongo'
