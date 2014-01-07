# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  update_name = ->
    value = $("#scraper_scraperwiki_url").val()
    m = value.match(/https:\/\/classic.scraperwiki.com\/scrapers\/(\w+)(\/)?/)    
    $("#scraper_name").val(m[1]) if m

  update_name()
  $("#scraper_scraperwiki_url").change(update_name)
  $("#scraper_scraperwiki_url").keyup(update_name)
