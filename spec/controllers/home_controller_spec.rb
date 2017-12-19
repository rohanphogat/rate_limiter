require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'index - test api_rate_limit before filter' do

    it 'should return 200 and render ok when api rate limit is not reached' do
      mock_rate_limiter = double('ApiThrottleService::RateLimiter')
      expect(ApiThrottleService::RateLimiter).to receive(:new).with("#{request.remote_ip}", 'home', 'index').and_return(mock_rate_limiter)
      expect(mock_rate_limiter).to receive(:validate_request).and_return(true)
      get :index
      expect(response.code).to eq("200")
      expect(response.body).to eq("ok")
    end

    it 'should return code 429 and render appropriate message when api rate limit is reached' do
      mock_rate_limiter = double('ApiThrottleService::RateLimiter')
      expect(ApiThrottleService::RateLimiter).to receive(:new).with("#{request.remote_ip}", 'home', 'index').and_return(mock_rate_limiter)
      expect(mock_rate_limiter).to receive(:validate_request).and_return(false)
      expect(mock_rate_limiter).to receive(:remaining_time).and_return(10)
      get :index
      expect(response.code).to eq("429")
      expect(response.body).to eq("Rate Limit Exceeded, Try again in 10 seconds")
    end

  end
end
