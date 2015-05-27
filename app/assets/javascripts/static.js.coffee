# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  animateMetric = $(".metric-box strong").each ->
    $this = $(this)
    jQuery(counter: 0).animate { counter: $this.text().replace(/\,/g, '') },
      duration: 3000
      easing: 'swing'
      step: ->
        $this.text Math.ceil(@counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
        return
    return
