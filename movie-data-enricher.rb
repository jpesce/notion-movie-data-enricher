require "json"
require "date"
require "dotenv/load"
require_relative "lib/tmdb.rb"
require_relative "lib/notion.rb"
require_relative "lib/logging.rb"
require_relative "lib/imdb.rb"

logger = Logging.logger
logger.level = Logger::INFO

def search_movie(notion_page)
  include Logging

  # Try TMDB link first
  tmdb_link = notion_page["properties"]["TMDB link"]["url"]
  if tmdb_link
    tmdb_id = tmdb_link.split("/").last
    tmdb_type = tmdb_link.split("/")[-2]
    logger.info("Found TMDB link, using ID: #{tmdb_id} of type #{tmdb_type}")
    return TMDB.get_details(tmdb_id, append_to_response: "external_ids", type: tmdb_type)
  end

  # Try IMDb link second
  imdb_link = notion_page["properties"]["IMDb link"]["url"]
  if imdb_link
    imdb_id = imdb_link.split("?").first.split("/").last
    logger.info("Found IMDb link, using ID: #{imdb_id}")
    result = TMDB.find_by_external_id(imdb_id)

    # The find_by_external_id returns results in movie_results and tv_results arrays
    type = nil
    if result["movie_results"].any?
      type = "movie"
    elsif result["tv_results"].any?
      type = "tv"
    end

    if type
      id = result["#{type}_results"].first["id"]
      return TMDB.get_details(id, type: type)
    end
  end

  # Fallback to specific type searches
  title = notion_page["properties"]["Name"]["title"][0]["plain_text"]
  year = notion_page["properties"]["Year"]["number"]
  logger.info("No external links found, searching for movie with title: #{title} and year: #{year}")
  
  # Try movie search first
  result = TMDB.search(title, year: year, type: "movie")
  if result && !result.empty?
    return TMDB.get_details(result["id"], append_to_response: "external_ids", type: "movie")
  end

  # If no movie found, try TV search
  logger.info("No movie found, searching for TV show with title: #{title} and year: #{year}")
  result = TMDB.search(title, year: year, type: "tv")
  if result && !result.empty?
    return TMDB.get_details(result["id"], append_to_response: "external_ids", type: "tv")
  end

  logger.error("No results found for title: #{title} and year: #{year}")
  return nil
end

def enrich_notion_movie_page(movie_page)
  title = movie_page["properties"]["Name"]["title"][0]["plain_text"]
  year = movie_page["properties"]["Year"]["number"]
  page_id = movie_page["id"]

  # TMDB - Title info
  tmdb_info = search_movie(movie_page)
  
  if tmdb_info.nil?
    logger.error("Could not find movie information for: #{title}")
    return
  end

  title = tmdb_info["title"] || tmdb_info["name"]
  original_title = tmdb_info["original_title"] || tmdb_info["original_name"]
  poster = "https://image.tmdb.org/t/p/original#{tmdb_info["poster_path"]}"
  release_date = tmdb_info["release_date"] || tmdb_info["first_air_date"]
  release_year = Date.parse(release_date).year
  genres = tmdb_info["genres"]
  imdb_id = tmdb_info["external_ids"]["imdb_id"]
  tmdb_id = tmdb_info["id"]
  media_type = tmdb_info["media_type"]

  # Get IMDb rating if we have an IMDb ID
  imdb_rating = nil
  if imdb_id
    imdb_rating = IMDB.get_rating(imdb_id)
  end

  # TMDB - Movie credits
  tmdb_credits = TMDB.get_credits(tmdb_info["id"], type: media_type)

  crew = tmdb_credits["crew"]
  directors = crew.select{ |person| person["job"] == "Director" }.map{ |director| director["name"] }

  # If no directors are found, use creator
  if directors.size == 0 
    directors = crew.select{ |person| person["job"] == "Creator" }.map{ |creator| creator["name"] }
  end

  # Notion - Update page
  page_title = original_title == title ? original_title : "#{original_title} (#{title})"
  update_body = {
    "cover": {
      "type": "external",
      "external": {
        "url": poster
      }
    },
    "properties": {
      "Name": {
        "title": [
          {
            "text": {
              "content": page_title
            }
          }
        ]
      },
      "Director": {
        "multi_select": directors.map{ |director| { "name": director }}
      },
      "Year": {
        "number": release_year
      },
      "Genres": {
        "multi_select": genres.map{ |genre| { "name": genre["name"] }}
      },
      "TMDB link": {
        "url": "https://www.themoviedb.org/#{media_type}/#{tmdb_id}"
      },
      "Enriched": {
        "checkbox": true
      }
    }
  }

  if imdb_id
    update_body[:properties]["IMDb link"] = { "url": "https://www.imdb.com/title/#{imdb_id}/" }
  end

  if imdb_rating
    update_body[:properties]["IMDb rating"] = { "number": imdb_rating }
  end

  Notion.update_page_properties(page_id, update_body)
end

logger.info {"Application started"}

begin
  notion_db_id = "db15f0674d7049158446337615e54bc3"
  query = {
    "filter": {
      "and": [
        {
          "property": "Enriched",
          "checkbox": {
            "equals": false
          }
        },
        {
          "property": "Name",
          "title": {
            "is_not_empty": true
          }
        }
      ]
    }
  }
  response = Notion.query_database(notion_db_id, query)
  notion_pages = JSON.parse(response.read_body)["results"]

  human_readable_movies = notion_pages.map{ |page| { "id": page["id"], "name": page["properties"]["Name"]["title"][0]["plain_text"]}}
  logger.info { "Querying Notion for entries to be updated - #{human_readable_movies.size} MOVIES FOUND - " + human_readable_movies.inspect }

  notion_pages.each do |page|
    begin
      enrich_notion_movie_page(page)
    rescue => e
      logger.error { e }
    end
  end
  logger.info("Application finished")

rescue => e
  logger.error { e }
end
