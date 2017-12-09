<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [RequestResponseStats](#requestresponsestats)
  - [Prerequisites](#prerequisites)
  - [Installation and Setup](#installation-and-setup)
  - [Usage](#usage)
    - [Documentation References](#documentation-references)
    - [Checking current data in redis](#checking-current-data-in-redis)
    - [Manually moving data from Redis to Mongo](#manually-moving-data-from-redis-to-mongo)
    - [Deleting data from Redis and Mongo](#deleting-data-from-redis-and-mongo)
    - [Getting stats from Mongo](#getting-stats-from-mongo)
  - [Development](#development)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# RequestResponseStats

[![Gem Version](https://badge.fury.io/rb/request_response_stats.svg)](https://badge.fury.io/rb/request_response_stats)
[![Build Status](https://travis-ci.org/goyalmunish/request_response_stats.svg?branch=master)](https://travis-ci.org/goyalmunish/request_response_stats)
[![codecov](https://codecov.io/gh/goyalmunish/request_response_stats/branch/master/graph/badge.svg)](https://codecov.io/gh/goyalmunish/request_response_stats)
[![Maintainability](https://api.codeclimate.com/v1/badges/0c231c47679470213426/maintainability)](https://codeclimate.com/github/goyalmunish/request_response_stats/maintainability)
[![Inline docs](http://inch-ci.org/github/goyalmunish/request_response_stats.svg?branch=master)](http://inch-ci.org/github/goyalmunish/request_response_stats)

## Prerequisites

The gem uses [Redis](https://github.com/redis/redis-rb) as a temporary storage to store the captured stats data. For permanent storage of this data, [MongoDB](https://github.com/mongodb/mongoid) is being used.

You can pass your redis connection (by default, it is assumed to be available through `$redis`) and mongoid_doc_model (by default, it is named `ReqResStat`) through `RequestResponseStats::RequestResponse.new`.

## Installation and Setup

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

Include `RequestResponseStats::ControllerConcern` to the controller whose request response stats are to be captured. For example,

```ruby
class ApplicationController < ActionController::Base
  include RequestResponseStats::ControllerConcern
  # rest of the code
end
```

Generate customization files:

```ruby
$ rails g request_response_stats:customization
```

Configure `config/initializers/request_response_stat_config.rb` as per your requirement.

## Usage

### Documentation References

Refer: http://www.rubydoc.info/gems/request_response_stats/

But, you can get better documentation by running tests :wink:.

### Checking current data in redis

```ruby
# include RequestResponseStats
rrs = RequestResponse.new(nil, nil)
rrs.redis_record.all_keys
rrs.redis_record.all_keys(support: true)
# [
#   [ 0] "api_req_res_SUPPORT_Munishs-MacBook-Pro.local_Munishs-MacBook-Pro.local_memory",
#   [ 1] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words_GET_2017-12-03-0202",
#   [ 2] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words_GET_2017-12-03-0200",
#   [ 3] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/6/ajax_promote_flag_GET_2017-12-03-0200",
#   [ 4] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/5/ajax_promote_flag_GET_2017-12-03-0200",
#   [ 5] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/4_GET_2017-12-03-0200",
#   [ 6] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/3_GET_2017-12-03-0202",
#   [ 7] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/3_GET_2017-12-03-0200",
#   [ 8] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/2_GET_2017-12-03-0200",
#   [ 9] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET_2017-12-03-0202",
#   [10] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/users_GET_2017-12-03-0205",
#   [11] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/users_GET_2017-12-03-0202",
#   [12] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/users_GET_2017-12-03-0201",
#   [13] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/generals/2_GET_2017-12-03-0205",
#   [14] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/flags_GET_2017-12-03-0202",
#   [15] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/dictionaries_GET_2017-12-03-0201",
#   [16] "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/admins/1_GET_2017-12-03-0201"
# ]
rrs.redis_record.all_keys.size
# 16
rrs.redis_record.hashify_all_data
```

Example on how data within each key looks like:

```ruby
rrs.redis_record.hashify_all_data["api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET_2017-12-03-0202"]
# =>
{
              "key_name" => "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET_2017-12-03-0202",
           "server_name" => "Munishs-MacBook-Pro.local",
              "api_name" => "/words/1/ajax_promote_flag",
              "api_verb" => "GET",
        "api_controller" => "words",
            "api_action" => "ajax_promote_flag",
         "request_count" => 3,
              "min_time" => 0.06,
              "max_time" => 0.095,
              "avg_time" => 0.075,
            "start_time" => "2017-12-03 03:22:00 UTC",
              "end_time" => "2017-12-03 03:23:00 UTC",
           "error_count" => 0,
    "min_used_memory_MB" => 0,
    "max_used_memory_MB" => 0,
    "avg_used_memory_MB" => 0,
    "min_swap_memory_MB" => 0,
    "max_swap_memory_MB" => 0,
    "avg_swap_memory_MB" => 0,
      "avg_gc_stat_diff" => {
                                          "count" => 0,
                           "heap_allocated_pages" => 0,
                             "heap_sorted_length" => 0,
                         "heap_allocatable_pages" => 0,
                           "heap_available_slots" => 0,
                                "heap_live_slots" => -1212,
                                "heap_free_slots" => -106,
                               "heap_final_slots" => 0,
                              "heap_marked_slots" => -1563,
                               "heap_swept_slots" => -91636,
                                "heap_eden_pages" => -3,
                                "heap_tomb_pages" => 0,
                          "total_allocated_pages" => 0,
                              "total_freed_pages" => 0,
                        "total_allocated_objects" => 12121,
                            "total_freed_objects" => 12025,
                          "malloc_increase_bytes" => 178165,
                    "malloc_increase_bytes_limit" => -186507,
                                 "minor_gc_count" => 0,
                                 "major_gc_count" => 0,
              "remembered_wb_unprotected_objects" => 0,
        "remembered_wb_unprotected_objects_limit" => 0,
                                    "old_objects" => 0,
                              "old_objects_limit" => 0,
                       "oldmalloc_increase_bytes" => -134054,
                 "oldmalloc_increase_bytes_limit" => 0
    },
      "min_gc_stat_diff" => {
                                          "count" => 0,
                           "heap_allocated_pages" => 0,
                             "heap_sorted_length" => 0,
                         "heap_allocatable_pages" => 0,
                           "heap_available_slots" => 0,
                                "heap_live_slots" => -3846,
                                "heap_free_slots" => -106,
                               "heap_final_slots" => 0,
                              "heap_marked_slots" => -4688,
                               "heap_swept_slots" => -300588,
                                "heap_eden_pages" => -9,
                                "heap_tomb_pages" => 0,
                          "total_allocated_pages" => 0,
                              "total_freed_pages" => 0,
                        "total_allocated_objects" => 10513,
                            "total_freed_objects" => 10437,
                          "malloc_increase_bytes" => -324416,
                    "malloc_increase_bytes_limit" => -559519,
                                 "minor_gc_count" => 0,
                                 "major_gc_count" => 0,
              "remembered_wb_unprotected_objects" => 0,
        "remembered_wb_unprotected_objects_limit" => 0,
                                    "old_objects" => 0,
                              "old_objects_limit" => 0,
                       "oldmalloc_increase_bytes" => -1261072,
                 "oldmalloc_increase_bytes_limit" => 0
    },
      "max_gc_stat_diff" => {
                                          "count" => 0,
                           "heap_allocated_pages" => 0,
                             "heap_sorted_length" => 0,
                         "heap_allocatable_pages" => 0,
                           "heap_available_slots" => 0,
                                "heap_live_slots" => 106,
                                "heap_free_slots" => -106,
                               "heap_final_slots" => 0,
                              "heap_marked_slots" => 0,
                               "heap_swept_slots" => 12840,
                                "heap_eden_pages" => 0,
                                "heap_tomb_pages" => 0,
                          "total_allocated_pages" => 0,
                              "total_freed_pages" => 0,
                        "total_allocated_objects" => 12925,
                            "total_freed_objects" => 12819,
                          "malloc_increase_bytes" => 429456,
                    "malloc_increase_bytes_limit" => 0,
                                 "minor_gc_count" => 0,
                                 "major_gc_count" => 0,
              "remembered_wb_unprotected_objects" => 0,
        "remembered_wb_unprotected_objects_limit" => 0,
                                    "old_objects" => 0,
                              "old_objects_limit" => 0,
                       "oldmalloc_increase_bytes" => 429456,
                 "oldmalloc_increase_bytes_limit" => 0
    }
}
```

The gem uses [free](https://linux.die.net/man/1/free) command to capture memory information of the server. If this command is not available (such as on Mac), then zeros are reported, as you can see in memory keys (keys ending with `memory_MB`) in the above example.

The last part of the key (such as `0202` in the above key) represents slot within a day. By default, `GROUP_STATS_BY_TIME_DURATION` is set as `1.minute`, so there are `24*60` slots in a day. You can easily configure these settings by overriding these configurations in`request_response_stats_config.rb`.

The `request_count` key, within data of a single key, gives the number of requests received for a given endpoint in a given timeslot.

For example, consider the key `"api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET_2017-12-03-0202"`:

```ruby
rrs.redis_record.get_slot_range_for_key "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET_2017-12-03-0202"
# =>
[
    [0] 2017-12-03 03:22:00 UTC,
    [1] 2017-12-03 03:23:00 UTC
]
```

This means that the server `Munishs-MacBook-Pro.local` received `3` (as reported by `request_count`) `GET` requests in between `2017-12-03 03:22:00 UTC` and `2017-12-03 03:23:00 UTC` for the endpoint `/words/1/ajax_promote_flag`.

### Manually moving data from Redis to Mongo

Moving only request_response_stats specific, freezed, non-support (that is `{support: false}`) keys from Redis to Mongo:

```ruby
rrs.move_data_from_redis_to_mongo  # => 16
```

Note: Make use of `lib/tasks/move_req_res_cycle_data_from_redis_to_mongo.rake` to schedule this task using cron.

### Deleting data from Redis and Mongo

```ruby
rrs.redis_record.all_keys.each{|k| rrs.redis_record.del k}
ReqResStat.all.delete_all
```

### Getting stats from Mongo

```ruby
ReqResStat.all.size  # => 16
ReqResStat.all.first
# => #<RequestResponseStats::ReqResStat _id: 5a237d55af9080aa7890a968, key_name: "api_req_res_PUBLIC_Munishs-MacBook-Pro.local_/words_GET_2017-12-03-0202", server_name: "Munishs-MacBook-Pro.local", api_name: "/words", api_verb: "GET", api_controller: "words", api_action: "index", request_count: 2, min_time: 2.392, max_time: 2.518, avg_time: 2.455, start_time: 2017-12-03 03:22:00 UTC, end_time: 2017-12-03 03:23:00 UTC, error_count: 0, min_used_memory_MB: 0, max_used_memory_MB: 0, avg_used_memory_MB: 0, min_swap_memory_MB: 0, max_swap_memory_MB: 0, avg_swap_memory_MB: 0, avg_gc_stat_diff: {"count"=>2, "heap_allocated_pages"=>0, "heap_sorted_length"=>0, "heap_allocatable_pages"=>0, "heap_available_slots"=>0, "heap_live_slots"=>-84476, "heap_free_slots"=>41108, "heap_final_slots"=>0, "heap_marked_slots"=>30927, "heap_swept_slots"=>76787, "heap_eden_pages"=>11, "heap_tomb_pages"=>-16, "total_allocated_pages"=>0, "total_freed_pages"=>0, "total_allocated_objects"=>687446, "total_freed_objects"=>732295, "malloc_increase_bytes"=>-517200, "malloc_increase_bytes_limit"=>-1131380, "minor_gc_count"=>2, "major_gc_count"=>0, "remembered_wb_unprotected_objects"=>2595, "remembered_wb_unprotected_objects_limit"=>0, "old_objects"=>21045, "old_objects_limit"=>0, "oldmalloc_increase_bytes"=>-4731008, "oldmalloc_increase_bytes_limit"=>0}, min_gc_stat_diff: {"count"=>2, "heap_allocated_pages"=>0, "heap_sorted_length"=>0, "heap_allocatable_pages"=>0, "heap_available_slots"=>0, "heap_live_slots"=>-84476, "heap_free_slots"=>-2260, "heap_final_slots"=>0, "heap_marked_slots"=>30927, "heap_swept_slots"=>7213, "heap_eden_pages"=>6, "heap_tomb_pages"=>-16, "total_allocated_pages"=>0, "total_freed_pages"=>0, "total_allocated_objects"=>687446, "total_freed_objects"=>692668, "malloc_increase_bytes"=>-517200, "malloc_increase_bytes_limit"=>-1177069, "minor_gc_count"=>2, "major_gc_count"=>0, "remembered_wb_unprotected_objects"=>2329, "remembered_wb_unprotected_objects_limit"=>0, "old_objects"=>21045, "old_objects_limit"=>0, "oldmalloc_increase_bytes"=>-4731008, "oldmalloc_increase_bytes_limit"=>0}, max_gc_stat_diff: {"count"=>2, "heap_allocated_pages"=>0, "heap_sorted_length"=>0, "heap_allocatable_pages"=>0, "heap_available_slots"=>0, "heap_live_slots"=>-84476, "heap_free_slots"=>84476, "heap_final_slots"=>0, "heap_marked_slots"=>30927, "heap_swept_slots"=>146361, "heap_eden_pages"=>16, "heap_tomb_pages"=>-16, "total_allocated_pages"=>0, "total_freed_pages"=>0, "total_allocated_objects"=>687446, "total_freed_objects"=>771922, "malloc_increase_bytes"=>-517200, "malloc_increase_bytes_limit"=>-1085691, "minor_gc_count"=>2, "major_gc_count"=>0, "remembered_wb_unprotected_objects"=>2862, "remembered_wb_unprotected_objects_limit"=>0, "old_objects"=>21045, "old_objects_limit"=>0, "oldmalloc_increase_bytes"=>-4731008, "oldmalloc_increase_bytes_limit"=>0}>
t = Time.now
ReqResStat.get_max(:max_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
# => [nil, nil, nil, nil, nil, nil, nil, 3.96]
ReqResStat.get_avg(:avg_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
#  => [0, 0, 0, 0, 0, 0, 0, 0.72]
ReqResStat.get_max(:min_time, t - 2.day, t, 6.hours).map{|r| r[:data]}
ReqResStat.get_details(:max_time, t - 2.day, t, nil, 6.hours)
# =>
[
    [0] {
              :data => {},
        :start_time => 2017-12-01 04:33:38 UTC,
          :end_time => 2017-12-01 10:33:38 UTC
    },
    [1] {
              :data => {},
        :start_time => 2017-12-01 10:33:38 UTC,
          :end_time => 2017-12-01 16:33:38 UTC
    },
    [2] {
              :data => {},
        :start_time => 2017-12-01 16:33:38 UTC,
          :end_time => 2017-12-01 22:33:38 UTC
    },
    [3] {
              :data => {},
        :start_time => 2017-12-01 22:33:38 UTC,
          :end_time => 2017-12-02 04:33:38 UTC
    },
    [4] {
              :data => {},
        :start_time => 2017-12-02 04:33:38 UTC,
          :end_time => 2017-12-02 10:33:38 UTC
    },
    [5] {
              :data => {},
        :start_time => 2017-12-02 10:33:38 UTC,
          :end_time => 2017-12-02 16:33:38 UTC
    },
    [6] {
              :data => {},
        :start_time => 2017-12-02 16:33:38 UTC,
          :end_time => 2017-12-02 22:33:38 UTC
    },
    [7] {
              :data => {
                                "Munishs-MacBook-Pro.local_/words_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words_GET",
                               :data => 2.518
                },
                [1] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words_GET",
                               :data => 3.962
                }
            ],
            "Munishs-MacBook-Pro.local_/words/6/ajax_promote_flag_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/6/ajax_promote_flag_GET",
                               :data => 0.118
                }
            ],
            "Munishs-MacBook-Pro.local_/words/5/ajax_promote_flag_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/5/ajax_promote_flag_GET",
                               :data => 0.069
                }
            ],
                              "Munishs-MacBook-Pro.local_/words/4_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/4_GET",
                               :data => 0.526
                }
            ],
                              "Munishs-MacBook-Pro.local_/words/3_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/3_GET",
                               :data => 0.286
                },
                [1] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/3_GET",
                               :data => 0.671
                }
            ],
                              "Munishs-MacBook-Pro.local_/words/2_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/2_GET",
                               :data => 0.458
                }
            ],
            "Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/words/1/ajax_promote_flag_GET",
                               :data => 0.095
                }
            ],
                                "Munishs-MacBook-Pro.local_/users_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/users_GET",
                               :data => 0.603
                },
                [1] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/users_GET",
                               :data => 0.319
                },
                [2] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/users_GET",
                               :data => 0.288
                }
            ],
                           "Munishs-MacBook-Pro.local_/generals/2_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/generals/2_GET",
                               :data => 0.431
                }
            ],
                                "Munishs-MacBook-Pro.local_/flags_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/flags_GET",
                               :data => 0.582
                }
            ],
                         "Munishs-MacBook-Pro.local_/dictionaries_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/dictionaries_GET",
                               :data => 0.397
                }
            ],
                             "Munishs-MacBook-Pro.local_/admins/1_GET" => [
                [0] {
                    :server_plus_api => "Munishs-MacBook-Pro.local_/admins/1_GET",
                               :data => 0.343
                }
            ]
        },
        :start_time => 2017-12-02 22:33:38 UTC,
          :end_time => 2017-12-03 04:33:38 UTC
    }
]

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
