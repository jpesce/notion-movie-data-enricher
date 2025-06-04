require "net/http"
require "json"
require_relative "logging"
require_relative "../util/extend_net"

module IMDB
  include Logging

  GRAPHQL_ENDPOINT = "https://graph.imdbapi.dev/v1"

  def self.get_rating(imdb_id)
    query = <<~GRAPHQL
      {
        title(id: "#{imdb_id}") {
          rating {
            aggregate_rating
          }
        }
      }
    GRAPHQL

    uri = URI(GRAPHQL_ENDPOINT)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = { query: query }.to_json

    logger.info("Querying IMDb for rating of #{imdb_id} - REQUEST - " + request.to_json)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    logger.info("Querying IMDb for rating of #{imdb_id} - RESPONSE - " + response.to_json)

    if response.is_a?(Net::HTTPSuccess)
      return JSON.parse(response.body)["data"]["title"]["rating"]["aggregate_rating"]
    end

    nil
  end
end 