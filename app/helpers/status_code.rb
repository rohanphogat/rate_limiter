module StatusCode
  SUCCESS = 200
  ERROR_API_LIMIT_REACHED = 429

  MESSAGES = {
    200 => 'Success',
    429 => "Rate Limit Exceeded, Try again in %s seconds"
  }

  def self.get_response_message(code, variables=[])
    (MESSAGES.key? code) ? MESSAGES[code] % variables : ''
  end
end