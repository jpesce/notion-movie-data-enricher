require "logger"

module Logging
  class << self
    def logger
      @logger ||= Logger.new('log/movie-data-enricher.log', 'daily', progname: "The Catalog Movie Data Enricher")
    end

    def logger=(logger)
      @logger = logger
    end
  end

  def self.included(base)
    class << base
      def logger
        Logging.logger
      end
    end
  end

  def logger
    Logging.logger
  end
end

