# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  update_name = ->
    value = $("#scraper_scraperwiki_shortname").val()
    $("#scraper_name").val(value) if value

  $("#scraper_scraperwiki_shortname").change(update_name)
  $("#scraper_scraperwiki_shortname").keyup(update_name)
