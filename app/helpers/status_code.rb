module StatusCode
  SUCCESS = 200
  ERROR_API_LIMIT_REACHED = 429

  MESSAGES = {
    200 => 'ok',
    429 => "Rate Limit Exceeded, Try again in %s seconds"
  }

  #returns appropriate messages for status codes, with variables replaced in strings if required
  def self.get_response_message(code, variables=[])
    (MESSAGES.key? code) ? MESSAGES[code] % variables : ''
  end
end