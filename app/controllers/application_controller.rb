class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def api_rate_limit
    @rate_limiter = ApiThrottleService::RateLimiter.new(request.remote_ip, params['controller'], params['action'])
    if !@rate_limiter.validate_request
      render :status => 429, plain: StatusCode.get_response_message(StatusCode::ERROR_API_LIMIT_REACHED, @rate_limiter.remaining_time)
    end
  end

end
