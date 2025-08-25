require "net/http"
require "json"
require_relative "logging"
require_relative "../util/extend_net"

module IMDB
  include Logging

  BASE_URL = "https://api.imdbapi.dev/"

  def self.get_rating(imdb_id)
    uri = URI("#{BASE_URL}titles/#{imdb_id}")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"

    logger.info("Querying IMDb for rating of #{imdb_id} - REQUEST - " + request.to_json)
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
    logger.info("Querying IMDb for rating of #{imdb_id} - RESPONSE - " + response.to_json)

    if response.is_a?(Net::HTTPSuccess)
      return JSON.parse(response.body)["rating"]["aggregate_rating"]
    end

    nil
  end
end 