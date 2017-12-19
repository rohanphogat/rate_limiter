ApiThrottle.configure do |config|
  config.time_window = 3600
  config.requests_per_window = 100
  config.min_time_bucket_size = 1
end