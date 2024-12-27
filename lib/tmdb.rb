require "uri"
require "dotenv/load"
require_relative "../util/extend_net.rb"

module TMDB
  TMDB_AUTHORIZATION = "Bearer #{ENV["TMDB_TOKEN"]}"

  def self.get_multi(title, year:)
    include Logging

    url = URI.parse(URI::Parser.new.escape("https://api.themoviedb.org/3/search/multi?query=#{title}&year=#{year}&include_adult=false"))
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["Accept"] = "application/json"
    request["Authorization"] = TMDB_AUTHORIZATION

    logger.info("Searching TMDB for title #{title}#{year && " (#{year})"} - REQUEST - " + request.to_json)
    response = https.request(request)
    logger.info("Searching TMDB for title #{title}#{year && " (#{year})"} - RESPONSE - " + response.to_json)

    json_response = JSON.parse(response.read_body)
    # Priority is movie
    movies = json_response["results"].select{ |result| result["media_type"] == "movie" }
    if movies.size > 0 then return movies[0] end

    # If no movie is found, return TV
    tv = json_response["results"].select{ |result| result["media_type"] == "tv"}
    if tv.size > 0 then return tv[0] end

    # Otherwise, return empty
    return []
  end

  def self.get_credits(id, type: "movie")
    url = URI("https://api.themoviedb.org/3/#{type}/#{id}/credits?language=en-US")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["Accept"] = "application/json"
    request["Authorization"] = TMDB_AUTHORIZATION

    logger.info("Querying TMDB for credits for title #{id}, type: #{type} - REQUEST - " + request.to_json)
    response = https.request(request)
    logger.info("Querying TMDB for credits for title #{id}, type: #{type} - RESPONSE - " + response.to_json)

    return JSON.parse(response.read_body)
  end
end
