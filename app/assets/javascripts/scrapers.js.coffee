# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

console_scroll_to_bottom = ->
  objDiv = document.getElementById("log_lines")
  if objDiv != null
    objDiv.scrollTop = objDiv.scrollHeight

# Always start with the console scrolled to the end
$ -> console_scroll_to_bottom()

class Sync.LogLineLogLine extends Sync.View
  afterInsert: -> console_scroll_to_bottom()

class Sync.ScraperShowPartial extends Sync.View
  afterUpdate: -> console_scroll_to_bottom()

class Sync.ScraperShowPartial extends Sync.View
  afterUpdate: -> $('time[data-time-ago]').timeago()

bindCapitalise = (j) ->
  j.on "input", ->
    input = $(this)
    start = input[0].selectionStart
    val = input.val()
    val = val.toUpperCase()
    if val[0..5] != "MORPH_"
      val = "MORPH_"
      start = 6
    input.val(val)
    input[0].selectionStart = start
    input[0].selectionEnd = start


$ ->
  bindCapitalise($("form.scraper .nested-fields .name"))
  $('#variables')
    .on 'cocoon:before-insert', (e, insertedItem) ->
      name = insertedItem.find(".name")
      name.val("MORPH_")
      bindCapitalise(name)
      insertedItem.fadeIn('fast')
    .on 'cocoon:before-remove', (e, removedItem) ->
      $(this).data('remove-timeout', 500)
      removedItem.fadeOut('fast')
