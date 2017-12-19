class ApiThrottleService::RateLimiter

  def initialize(ip, controller, action)
    @key = "api_rate_limit_#{ip}_#{controller}_#{action}"
    set_parameters
  end

  ###
  # request validator : decides whther or not api request should be allowed
  # Algo:
  # checks for key in redis and create/update it.
  # sets expiry if its a new key.
  # compares the latest value with request allowed per key existence time.
  # returns true if api rate limit is not reached or redis is down.
  # returns false if api rate limit is reached.
  #
  def validate_request
    begin
      key_exists = $redis.exists(@key)
      updated_api_request_count = $redis.incrby(@key,1)
      if !key_exists
        $redis.expire(@key, @expiry_time)
      end
      return false if updated_api_request_count > @req_per_time_slot
    rescue Redis::CannotConnectError
      Rails.logger.info 'redis server is down, allowing api call'
    end
    true
  end

  #returns remaining TTL for the given key
  def remaining_time
    $redis.ttl(@key)
  end

  private

  ###
  # Calculates expiry time for redis key, and maximum num of requests allowed for that key
  #
  # Algo:
  # Take time diff between 2 requests for uniform distribution of requests
  # compare it with minimum time slot size defined in config. 2 cases occur as follows:-
  #
  # 1. when multiple requests can go out in a single unit of 'minimum time slot'
  # set 'minimum time slot' as redis key expiry time
  # calculate num of multiple requests allowed in that time slot (for which the redis key will exist)
  #
  # 2. when single request can take more time than a unit of 'minimum time slot'
  # set expiry time equal to time difference between two requests.
  # num of requests allowed during the existence of the key will be equal to 1
  #
  def set_parameters
    time_per_request = time_window / requests_per_window
    if time_per_request <= min_time_slot_size
      @expiry_time = min_time_slot_size
      @req_per_time_slot = ((min_time_slot_size * requests_per_window)/time_window.to_f).round
    else
      @expiry_time = time_per_request
      @req_per_time_slot = 1
    end
  end

  # returns the minimum time slot size in seconds
  # determines the granularity of time slots and distribution of requests across time window
  # rate limiter will act as fixed window rate limiter if this is set equal to time_window
  def min_time_slot_size
    @min_slot_size ||= ApiThrottle.configuration.min_time_slot_size
  end

  # returns the time window in seconds
  def time_window
    @time_window ||= ApiThrottle.configuration.time_window
  end

  # returns the number of requests per time window
  def requests_per_window
    @requests_per_window ||= ApiThrottle.configuration.requests_per_window
  end

end