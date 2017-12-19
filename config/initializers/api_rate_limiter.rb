ApiThrottle.configure do |config|

  # time window in seconds
  config.time_window = 3600

  # number of requests per time window
  config.requests_per_window = 100

  # minimum time slot size in seconds
  # determines the granularity of time slots and distribution of requests across time window
  # rate limiter will act as fixed window rate limiter if this is set equal to time_window
  config.min_time_slot_size = 72

end