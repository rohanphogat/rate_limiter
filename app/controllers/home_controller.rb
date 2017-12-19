class HomeController < ApplicationController

  before_filter :api_rate_limit, only: :index

  def index
    render plain: StatusCode.get_response_message(StatusCode::SUCCESS)
  end

end