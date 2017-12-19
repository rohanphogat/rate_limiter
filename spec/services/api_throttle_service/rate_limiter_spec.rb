require 'rails_helper'

RSpec.describe ApiThrottleService::RateLimiter, type: :service do

  describe 'validate_request' do

    context 'config : time_window = 3600, requests_per_window = 100, min_time_bucket_size = 1' do
    #calculated rate limit 1 request every 36 seconds
    before(:each) do
      $redis.flushdb
      ApiThrottle.configure do |config|
        config.time_window = 3600
        config.requests_per_window = 100
        config.min_time_bucket_size = 1
      end
    end

      it 'should return true when api request has not reached rate limit' do
        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')
        expect(rate_limiter_service.validate_request).to eq(true)
        expect(rate_limiter_service.remaining_time).to be_within(1).of(36)
      end

      it 'should return true for first request and false for second when rate limit reached' do
        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')
        expect(rate_limiter_service.validate_request).to eq(true)
        expect(rate_limiter_service.validate_request).to eq(false)
        expect(rate_limiter_service.remaining_time).to be_within(1).of(36)
      end

    end

    context 'config : time_window = 3600, requests_per_window = 100, min_time_bucket_size = 3600' do
      #calculated rate limit 100 request every 3600 seconds
      before(:each) do
        $redis.flushdb
        ApiThrottle.configure do |config|
          config.time_window = 3600
          config.requests_per_window = 100
          config.min_time_bucket_size = 3600
        end
      end

      it 'should return true for first 100 requests and false for 101th request when rate limit reached' do
        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')

        100.times do
          expect(rate_limiter_service.validate_request).to eq(true)
        end

        expect(rate_limiter_service.validate_request).to eq(false)
        expect(rate_limiter_service.remaining_time).to be_within(1).of(3600)
      end

    end

    context 'config : time_window = 3600, requests_per_window = 7200, min_time_bucket_size = 1' do
      #calculated rate limit 2 requests every 1 second
      before(:each) do
        $redis.flushdb
        ApiThrottle.configure do |config|
          config.time_window = 3600
          config.requests_per_window = 7200
          config.min_time_bucket_size = 1
        end
      end

      it 'should return true for first 100 requests and false for next when rate limit reached' do
        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')

        2.times do
          expect(rate_limiter_service.validate_request).to eq(true)
        end

        expect(rate_limiter_service.validate_request).to eq(false)
        expect(rate_limiter_service.remaining_time).to be_within(1).of(1)
      end

    end

    context 'config : time_window = 3600, requests_per_window = 7200, min_time_bucket_size = 5' do
      #calculated rate limit 10 requests every 5 seconds
      before(:each) do
        $redis.flushdb
        ApiThrottle.configure do |config|
          config.time_window = 3600
          config.requests_per_window = 7200
          config.min_time_bucket_size = 5
        end
      end

      it 'should return true for first 100 requests and false for next when rate limit reached' do
        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')

        10.times do
          expect(rate_limiter_service.validate_request).to eq(true)
        end

        expect(rate_limiter_service.validate_request).to eq(false)
        expect(rate_limiter_service.remaining_time).to be_within(1).of(5)
      end

    end

    context 'when redis is down' do
      it 'should not error out and allow api call' do
        expect($redis).to receive(:hgetall).and_raise(Redis::CannotConnectError)
        expect(Rails).to receive_message_chain(:logger,:info).with('redis server is down, allowing api call')

        rate_limiter_service = ApiThrottleService::RateLimiter.new('1.1.1.1','test_controller','test_action')
        expect(rate_limiter_service.validate_request).to eq(true)
      end
    end

  end

end