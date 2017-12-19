require 'rails_helper'

RSpec.describe StatusCode, type: :helper do
  describe 'get_response_message' do

    it 'should return correct message for status code 200' do
      expect(StatusCode::SUCCESS).to eq(200)
      expect(StatusCode.get_response_message(StatusCode::SUCCESS)).to eq('ok')
    end

    it 'should return correct message with variable for status code 429' do
      expect(StatusCode::ERROR_API_LIMIT_REACHED).to eq(429)
      expect(StatusCode.get_response_message(StatusCode::ERROR_API_LIMIT_REACHED,10)).to eq('Rate Limit Exceeded, Try again in 10 seconds')
    end

  end
end