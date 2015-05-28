# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

roundUpBy = (value, round_to) ->
  return round_to * Math.ceil(value / round_to)

$ ->
  metricsInview = new (Waypoint.Inview)(
    element: $('.metric-box')[0]
    enter: (direction) ->
      $(".metric-box strong").each (index) ->
        $this = $(this)
        starting_point = 0
        $target_count = parseInt($this.text().replace(/\,/g, ''))
        $this.counter = starting_point

        tween = createjs.Tween.get($this).to( {counter: $target_count}, (500 + index * 200) , createjs.Ease.quintInOut)

        tween.addEventListener 'change', (event) ->
          $this.text(Math.round($this.counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","))
          return
      # only run this once
      this.destroy()
  )
