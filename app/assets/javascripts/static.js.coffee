# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  animateMetric = $(".metric-box strong").each (index) ->
    $this = $(this)
    starting_point = 0
    $target_count = parseInt($this.text().replace(/\,/g, ''))

    # set the test to 0
    $this.counter = starting_point

    tween = createjs.Tween.get($this).to( {counter: $target_count}, (1000 + index * 1000) , createjs.Ease.quintOut)

    tween.addEventListener 'change', (event) ->
      $this.text(Math.round($this.counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","))
      return
