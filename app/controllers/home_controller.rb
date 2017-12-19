class HomeController < ApplicationController

  before_filter :api_rate_limit, only: :index

  def index
    render plain: 'ok'
  end

end