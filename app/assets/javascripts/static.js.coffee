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
        $target_count = parseInt($this.text().replace(/\,/g, ''))

        jQuery(counter: 0).animate { counter: $target_count },
          duration: 400 + index * 200
          easing: "easeInOutQuint"
          step: ->
            $this.text Math.ceil(@counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
          complete: ->
            jQuery(counter: $target_count).animate { counter: (40 + $target_count) },
              duration: 400
              easing: "easeOutQuint"
              step: ->
                $this.text Math.ceil(@counter).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
                return
            return
        return
      # only run this once
      this.destroy()
  )
