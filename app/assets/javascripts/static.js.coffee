# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

roundUpBy = (value, round_to) ->
  return round_to * Math.ceil(value / round_to)

$ ->
  metricsInview = new (Waypoint.Inview)(
    element: $('.banner-metrics')[0]
    enter: (direction) ->
      $(".metric-box strong").each (index) ->
        $this = $(this)
        starting_point = 0
        $target_count = parseInt($this.text().replace(/\,/g, ''))
        $this.counter = starting_point

        tween = createjs.Tween.get($this).to( {counter: $target_count}, (1000 + index * 400) , createjs.Ease.quintOut)

        tween.addEventListener 'change', (event) ->
          # if the number is under 90 of the target, increment number by thousands
          if $this.counter < $target_count * 0.7
            $this.counter = roundUpBy($this.counter, 1000)
          else if $this.counter < $target_count * 0.8
            $this.counter = roundUpBy($this.counter, 100)
          else if $this.counter < $target_count * 0.99
            $this.counter = roundUpBy($this.counter, 10)
          $this.text(Math.round($this.counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ","))
          return
  )
