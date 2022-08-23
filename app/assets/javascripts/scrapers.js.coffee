# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

console_scroll_to_bottom = ->
  objDiv = document.getElementById("log-lines")
  if objDiv != null
    objDiv.scrollTop = objDiv.scrollHeight

# TODO: This should run again if TableSaw changes the
# layout.
findStartingPosition = (scroller_frame) ->
  scroller_panel = scroller_frame.find('.scroller-panel')

  frame_width = scroller_frame.width()
  panel_width = scroller_panel.width()

  if frame_width + 1 < panel_width
    scroller_frame.addClass("panel-scrollable")
    scroller_frame.addClass("panel-scrolled-left")
  else
    scroller_frame.removeClass("panel-scrolled-right")
    scroller_frame.removeClass("panel-scrolled-left")
    scroller_frame.removeClass("panel-scrolled-middle")

setScrollWatcher = (scroller_frame) ->
  scroller_panel = scroller_frame.find('.scroller-panel')
  frame_width = scroller_frame.width()
  panel_width = scroller_panel.width()

  scroller_frame.scroll ->
    scroller_frame = $(this)
    scroller_panel = scroller_frame.find('.scroller-panel')

    frame_width = scroller_frame.width()
    panel_width = scroller_panel.width()

    if scroller_frame.scrollLeft() == 0
      scroller_frame.addClass("panel-scrolled-left")
      scroller_frame.removeClass("panel-scrolled-right")
      scroller_frame.removeClass("panel-scrolled-middle")
    else if scroller_frame.scrollLeft() + frame_width + 2 > panel_width
      scroller_frame.addClass("panel-scrolled-right")
      scroller_frame.removeClass("panel-scrolled-left")
      scroller_frame.removeClass("panel-scrolled-middle")
    else
      scroller_frame.addClass("panel-scrolled-middle")
      scroller_frame.removeClass("panel-scrolled-right")
      scroller_frame.removeClass("panel-scrolled-left")

setScrollerFadeEffect = ->
  if $('.scroller-frame') && $('.scroller-panel')
    scroller_frame = $('#data-table .scroller-frame')

    findStartingPosition(scroller_frame)
    setScrollWatcher(scroller_frame)

    tab_links = []
    tab_links = $('#data-table .nav-tabs a')

    tab_links.each ->
      $(this).on 'shown.bs.tab', (e) ->
        active_tab = $($(this).attr('href'))
        scroller_frame = active_tab.find('.scroller-frame')

        setScrollWatcher(scroller_frame)
        findStartingPosition(scroller_frame)

$ -> setScrollerFadeEffect()

# Always start with the console scrolled to the end
$ -> console_scroll_to_bottom()

class RenderSync.LogLineLogLine extends RenderSync.View
  afterInsert: -> console_scroll_to_bottom()

class RenderSync.ScraperShowPartial extends RenderSync.View
  afterUpdate: ->
    console_scroll_to_bottom()
    $('time[data-time-ago]').timeago()
    $(document).trigger("enhance.tablesaw")
    setScrollerFadeEffect()

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
  bindCapitalise($("form.edit_scraper .nested-fields .name"))
  $('#variables')
    .on 'cocoon:before-insert', (e, insertedItem) ->
      name = insertedItem.find(".name")
      name.val("MORPH_")
      bindCapitalise(name)
      insertedItem.fadeIn('fast')
    .on 'cocoon:before-remove', (e, removedItem) ->
      $(this).data('remove-timeout', 500)
      removedItem.fadeOut('fast')

  # Enable Bootstrap's tooltips for webhook delivery status
  $('[data-toggle="tooltip"]').tooltip animation: false
