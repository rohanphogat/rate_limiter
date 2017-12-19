module ApiThrottle
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :time_window, :requests_per_window, :min_time_slot_size

    def initialize
      @time_window = 3600
      @requests_per_window = 100
      @min_time_slot_size = 1
    end
  end
end