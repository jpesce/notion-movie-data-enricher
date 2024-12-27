require "uri"
require "dotenv/load"
require_relative "../util/extend_net.rb"

module Notion
  NOTION_AUTHORIZATION = "Bearer #{ENV["NOTION_TOKEN"]}"
  NOTION_VERSION = ENV["NOTION_VERSION"]

  def self.update_page_properties(id, body)
    include Logging
    url = URI("https://api.notion.com/v1/pages/#{id}")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Patch.new(url)
    request["Authorization"] = NOTION_AUTHORIZATION
    request["Notion-Version"] = NOTION_VERSION
    request["Content-Type"] = "application/json"
    request.body = JSON.dump(body)

    logger.info("Updating notion page #{id} - REQUEST - " + request.to_json)
    response = https.request(request)
    logger.info("Updating Notion page #{id} - RESPONSE - " + response.to_json)

    return response
  end

  def self.filter_database(id, filter)
    include Logging

    url = URI("https://api.notion.com/v1/databases/#{id}/query")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(url)
    request["Authorization"] = NOTION_AUTHORIZATION
    request["Notion-Version"] = NOTION_VERSION
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({ "filter": filter })

    logger.info("Filtering Notion database #{id} - REQUEST - " + request.to_json)
    response = https.request(request)
    logger.info("Filtering Notion database #{id} - RESPONSE - " + response.to_json)

    return response
  end
end
