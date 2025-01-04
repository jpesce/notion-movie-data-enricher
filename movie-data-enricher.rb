require "json"
require "date"
require "dotenv/load"
require_relative "lib/tmdb.rb"
require_relative "lib/notion.rb"
require_relative "lib/logging.rb"

def enrich_notion_movie_page(movie_page)
  title = movie_page["properties"]["Name"]["title"][0]["plain_text"]
  year = movie_page["properties"]["Year"]["number"]
  page_id = movie_page["id"]

  # TMDB - Basic movie info
  tmdb_info = TMDB.get_multi(title, year: year)

  title = tmdb_info["title"] || tmdb_info["name"]
  original_title = tmdb_info["original_title"] || tmdb_info["original_name"]
  poster = "https://image.tmdb.org/t/p/original#{tmdb_info["poster_path"]}"
  release_date = tmdb_info["release_date"] || tmdb_info["first_air_date"]
  release_year = Date.parse(release_date).year
  type = tmdb_info["media_type"]

  # TMDB - Genres
  genres = tmdb_info["genre_ids"].map{ |genre_id| 
    TMDB.genres(type: type)["genres"].detect{ |genre| genre["id"] == genre_id }
  }
  genres_names = genres.map{ |genre| genre["name"] }

  # TMDB - Movie credits
  tmdb_credits = TMDB.get_credits(tmdb_info["id"], type: type)

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
          "text": {
            "content": page_title
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
        "multi_select": genres_names.map{ |genre| { "name": genre }}
      },
      "Don't enrich": {
        "checkbox": true
      }
    }
  }

  Notion.update_page_properties(page_id, update_body)
end

logger = Logging.logger
logger.level = Logger::INFO

logger.info {"Application started"}

begin
  notion_db_id = "db15f0674d7049158446337615e54bc3"
  filter = {
    "and": [
      {
        "property": "Don't enrich",
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
  response = Notion.filter_database(notion_db_id, filter)
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
