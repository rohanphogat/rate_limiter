# Rate Limiter

## Requirements

* Ruby v2.3.1

* Rails v5.0.6

* Redis server v3.0.6


## Gems used

* redis (for storage)

* rspec-rails (for writing tests, unit and integration)

* fakeredis (for running specs without actual redis)

* simplecov (for tracking test coverage)

## Usage
Ensure that there is a redis server instance running on your system at default port 6379.
This app is without a database, so no db commands or migrations are required to be run.
```
git clone https://github.com/rohanphogat/rate_limiter.git
cd rate_limiter
bundle install
rspec
rails s
```

## Key Decisions

### Possible Solutions(Ones that I did not use):
#### 1. Fixed window:
```

A basic implementation, where fixed time window are taken.
we allow fixed number of requests until the end of time window.

e.g. for 100 requests in 3600 seconds(1 hour):-
On receiving a request,
if key doesn't exist, set the redis key with value 1 and with expiry of 3600 seconds.
if key exists, increment the counter by 1. return false if counter becomes > 100.

    Problems: Due to fixed windows it will expire key when first api call time + 1 hour reaches.
              user can send almost twice the rate limit.
              lacks uniform distribution of api calls across time window
    e.g. Send 1 request now, then 99 request between 3659 and 3600 seconds from now.
    Another 99 requests between 3600 and 3601 seconds from now.

    Memory usage:(less)
        Assuming 4 bytes for counter, and 26 bytes for keys (string like '123.123.123.123_home_index')
        hash overhead of 20 bytes.
        Total for 1 user :- (26+4) + 20 = 50 Bytes
        For 1 million users:- 50*1,000,000 = 50 MB
```

#### 2. Sliding window:
```
In this algorithm, we maintain a sliding window by storing timestamps of each request in a sorted set.
So that instead of the key expiring when first api call time + 1.hour time is reached,
the expiry time of second api call time + 1 hour will be used and so on...

e.g. for 100 requests in 3600 seconds(1 hour):-
On receiving a new request, if key doesn't exist, create one with expiry 3600.
Remove all the timestamps from the Sorted Set that are older than Time.now - 1.hour
Return false if size of the sorted set > 100
Insert the current timestamp in the sorted set, and return true if size of the sorted set < 100

    Problems: High memory usage(bad trade off over time window).
              calculating size of sorted set is slower.
              lacks uniform distribution of api calls across time window

    Memory usage(very large):
        Assuming 4 bytes for a timestamp and 20 bytes overhead for sorted set
        26 bytes for keys (string like '123.123.123.123_home_index')
        hash overhead of 20 bytes.
        Total for 1 user :- 26 + (4+20)*100 + 20 = 2446 Bytes
        For 1 million users:- 2446*1,000,000 = 2.46 GB
```

#### 3. Per request window:
```
In this algorithm, instead of a counter, we calculate the acceptable rate of incoming api request calls.
i.e. the time difference between 2 requests and set it as expiry for given key.
This algorithm will ensure perfect uniform distribution of api calls across the mentioned time window.

e.g. for 100 requests in 3600 seconds(1 hour):-
It is equivalent to 1 request every 36 seconds.
On receiving a request,
If key already exists, return false.
If key doesn't exist, create a key with expiry of 36 seconds, and return true.

    Problems: too many and too fast read/writes to redis, when expected rate is large.
    e.g. if 36000 requests in 3600 seconds. then 1 request every 0.1 second.
    expiry key for redis key 0.1 second !! will get worse will larger rates.

    Memory usage:(less)
    similar to time_window algorithm. i.e. 50 MB
```

### Final Implemented Solution (A hybrid):-
```
In this algorithm, I am trying to take the best of 'time window' and 'per request' algorithms.
Apart from the 'time window' (3600 second) and request per time window (100),
we will define another customizable variable 'min time slot'.
This represents the smallest time slot that we want to use the rate limiter for.
We recalculate the rate limit for a smaller window, according to min_time_slot.
If minimum_time_slot > time difference between 2 api calls
    expiry time is same as minimum_time_slot
    calculate api requests allowed in this small window
If minimum_time_slot < time difference between 2 api calls
    expiry time is same as time difference between 2 api calls
    1 api request allowed in this small window

Finally we follow the same algo as 'time_window' but for our own calculated smaller window.

e.g. for 100 requests in 3600 seconds(1 hour) and min_time_slot 72 seconds :-
here we create buckets of 72 seconds each, and set recalculated rate limit as 2 api request calls per time slot.
On receiving an api call,
if key doesn't exist, set it with value counter 1, and expiry 72 seconds.
    (only 1 more api call will be allowed in next 72 seconds)
if key exists, increment the counter, if counter > 2, return false.
    if counter <= 2, return true

If the same example,
- If we set min_time_slot = 3600 seconds (same as time_window),
    then this algo will behave as time window algo.
- If we set min_time_slot = 1 second (too low, less than difference between 2 api calls),
    then this algo will behave as per request window algo.

    Problems: extra config (due to 1 extra variable)

    Memory usage:(less)
        similar to time_window algorithm. i.e. 50 MB

refer services/api_throttle_services/rate_limiter_spec.rb in code for more examples

```
## Code
```
INITIALIZERS:

* api_rate_limiter.rb
    -   sets parameter time_window : time window in secondss
    -   sets parameter requests_per_window : number of requests per time window
    -   sets parameter min_time_slot_size : minimum time slot size in seconds

CONTROLLERS:

* ApplicationController
    -   Method api_rate_limit : calls the rate limiter service and renders 429 if rate limit reached.
* HomeController
    -   Action index: renders 200 ok if rate limit is not reached.
    -   before_filter: api_rate_limit (method defined in application controller)

SERVICES:

* ApiThrottleService::RateLimiter
    -   Implementation of rate limiter.

HELPERS:

* StatusCode
    -   Status codes and their corresponding messages generator.

SPECS:

* services/api_throttle_services/rate_limiter_spec.rb
* home_controller_spec.rb
* helpers/status_code_spec.rb

command : rspec
coverage : 100% (generated in "#{Rails.root}/coverage" after test run completion)


```

## Potential Improvement areas
* Can use Redis Lock : an important application of rate limiter is to prevent DOS attacks.
During such attacks, thousands of requests may come as a burst. This can lead to race conditions, where many processes are accessing same redis key.
In such a scenario, multiple request may get allowed, even though only a few should have been allowed and others rejected.

* Implement as middleware : If, like most applications, we want to use rate limiter globally across almost routes, it would be a better idea to implement it as a middleware, so that requests don't even reach the controller instances.

* make this a gem : Since rate limiter is very independent of actual app, it would be a good idea from code maintainability point of view to make it a separate gem.