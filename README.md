# RequestResponseStats

## Installation

Add gem to your application's Gemfile:

```ruby
gem 'request_response_stats'
```

And then execute:

```bash
$ bundle install
```

Or install it separately as:

```bash
$ gem install request_response_stats
```

Add following to the controller whose request response stats are to be captured. For example,

```ruby
class ApplicationController < ActionController::Base
  include RequestResponseStats::ControllerConcern
  # rest of the code
end
```

Right now there are some manual tasks:

- Copy file `lib/req_res_stat_controller.rb` from gem to `app/controllers/req_res_stat_controller.rb` within Rails app.
- Copy file `lib/request_response_stats_config.rb` from gem to `config/initializers/request_response_stat_config.rb` within Rails app
- Copy file `lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake` from gem to `lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake` within Rails app.

TODO: Write rake task for this.

## Usage

### Documentation References

http://www.rubydoc.info/gems/request_response_stats/

You can get better documentation by running tests.

TODO: Include examples for below commands.

### Checking current data in redis

```ruby
# include RequestResponseStats
rrs = RequestResponse.new(nil, nil)
rrs.redis_record.hashify_all_data.size
rrs.redis_record.hashify_all_data
```

### Manually moving data from Redis to Mongo

```ruby
rrs.move_data_from_redis_to_mongo 
```
Note: To automate use: lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake

### Deleting data from Redis and Mongo

```ruby
rrs.redis_record.all_keys.each{|k| rrs.redis_record.del k}
ReqResStat.all.delete_all
```

### Getting stats from Mongo

```ruby
ReqResStat.all.size
ReqResStat.all.first
t = Time.now
ReqResStat.get_max(:max_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
ReqResStat.get_avg(:avg_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
ReqResStat.get_max(:min_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
ReqResStat.get_details(:max_time, t - 2.day, t, nil, 6.hours)
ReqResStat.get_details(:max_time, t - 2.day, t, :max, 6.hours)
ReqResStat.get_details(:max_time, t - 2.day, t, :min, 6.hours)
ReqResStat.get_details(:max_time, t - 2.day, t, :sum, 6.hours)
ReqResStat.get_details(:max_time, t - 2.day, t, :avg, 6.hours)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goyalmunish/request_response_stats. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RequestResponseStats project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/goyalmunish/request_response_stats/blob/master/CODE_OF_CONDUCT.md).
