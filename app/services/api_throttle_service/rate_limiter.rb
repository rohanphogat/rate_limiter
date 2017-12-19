class ApiThrottleService::RateLimiter

  def initialize(ip, controller, action)
    @key = "#{ip}_#{controller}_#{action}"
    set_parameters
  end

  def validate_request
    begin
      current_data = $redis.hgetall(@key)
      if current_data.present?
        $redis.hincrby(@key,'counter',1)
        return false if current_data['counter'].to_i >= @req_per_bucket
      else
        $redis.hset(@key, 'start_time', Time.now.to_i)
        $redis.hset(@key, 'counter', 1)
        $redis.expire(@key, @expiry_time)
      end
    rescue Redis::CannotConnectError
      Rails.logger.info 'redis server is down, allowing api call'
    end
    true
  end

  def remaining_time
    @expiry_time - (Time.now.to_i - $redis.hget(@key, 'start_time').to_i)
  end

  private

  def set_parameters
    time_per_request = time_window / requests_per_window
    if time_per_request <= min_time_bucket_size
      @expiry_time = min_time_bucket_size
      @req_per_bucket = (min_time_bucket_size * requests_per_window)/time_window
    else
      @expiry_time = time_per_request
      @req_per_bucket = 1
    end
  end

  def min_time_bucket_size
    @min_bucket_size ||= ApiThrottle.configuration.min_time_bucket_size
  end

  def time_window
    @time_window ||= ApiThrottle.configuration.time_window
  end

  def requests_per_window
    @requests_per_window ||= ApiThrottle.configuration.requests_per_window
  end

end