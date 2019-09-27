#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'dotenv'
  gem 'contentful'
  gem 'contentful-management'
  gem 'csv'
  #gem 'byebug'
end

Dotenv.load

api_key = ENV["API_KEY"]
space_id = ENV["SPACE_ID"]
update_token = ENV["UPDATE_TOKEN"]
env = ENV["ENV"]

content_type = 'featuredPoints'

#feature_slugs = ["bestPlaces", "priorPlaces"]
best_places = "eo_wilson_best_places.csv"
priority_places = "GeodescriberWithIDs_review.csv"

fetch_client = Contentful::Client.new(
  space: space_id,  # This is the space ID. A space is like a project folder in Contentful terms
  access_token: api_key  # This is the access token for this space. Normally you get both ID and the token in the Contentful web app
)
update_client = Contentful::Management::Client.new(update_token)



### Update Best Places
# csv headers: slug, short_text, long_text
CSV.open(best_places, headers: true).each do |csv|
  puts "###################################"
  puts "BEST PLACES!!! Here we gooooo!!!!!!!!!!!!!!!"
  puts "###################################"
  entry = fetch_client.entries(content_type: content_type,
                             "fields.featureSlug": "bestPlaces",
                             "fields.nameSlug": csv["slug"]).first
  entry_id = entry.id
  if !entry_id
    puts "Failed to find bestPlace entry with slug #{csv["slug"]}"
    next
  end
  existing_description = entry.fields[:description]["content"].first["content"].first["value"]
  puts "Updating entry with id: #{entry_id} and nameSlug of #{entry.fields["nameSlug"]} and current description:"
  puts existing_description
  puts "###################################"
  puts "New text will be: #{csv["long_text"]}"

  update_entry = update_client.entries(space_id, env).find(entry_id)
  update_entry.fields[:description]["content"].first["content"].first["value"] = csv["long_text"]
  update_entry.save
end

### Update Priority Places
# csv headers: slug, title, description
CSV.open(priority_places, headers: true).each do |csv|
  puts "###################################"
  puts "PRIORITY_PLACES!!!! Here we gooooo!!!!!!!!!!!!!!!"
  puts "###################################"
  entry = fetch_client.entries(content_type: content_type,
                             "fields.featureSlug": "priorPlaces",
                             "fields.nameSlug": csv["slug"]).first
  entry_id = entry.id
  if !entry_id
    puts "Failed to find bestPlace entry with slug #{csv["slug"]}"
    next
  end
  puts "Updating entry with id: #{entry_id} and nameSlug of #{entry.fields["nameSlug"]}"
  puts "###################################"
  puts "Name will be: #{csv["title"]}"
  puts "Description will be: #{csv["description"]}"

  update_entry = update_client.entries(space_id, env).find(entry_id)
  description = {
    "content": [
      {
        "data": {},
        "content": [
          {
            "data": {},
            "marks": [],
            "value": csv["description"],
            "nodeType": "text"
          }
        ],
        "nodeType": "paragraph"
      }
    ],
    "data": {},
    "nodeType": "document"
  }
  update_entry.fields[:description] = description
  update_entry.fields["title"] = csv["title"]
  update_entry.save
end
