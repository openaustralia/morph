# As we're always showing all the users we can do one query to the database
# to get all the scraper counts for all the owners at once
scraper_count_by_owner = Scraper.group(:owner_id).count

json.array! @users do |user|
  json.created_at user.created_at
  json.nickname user.nickname
  json.number_scrapers (scraper_count_by_owner[user.id] || 0)
end
