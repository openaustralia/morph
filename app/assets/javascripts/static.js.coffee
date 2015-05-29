# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

formatNumberWithCommaDelimiter = (number) ->
  Math.ceil(number).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

animateNumber = (element, target_final_count, duration) ->
  # break the animation into two steps to exaggerate the easing
  step_one_target_count = if target_final_count > 10040 then target_final_count - 40 else target_final_count
  jQuery(counter: 0).animate { counter: step_one_target_count },
    duration: duration
    easing: "easeInOutQuint"
    step: ->
      element.text formatNumberWithCommaDelimiter(@counter)
    complete: ->
      if step_one_target_count != target_final_count
        jQuery(counter: step_one_target_count).animate { counter: (target_final_count) },
          duration: 400
          easing: "easeOutQuint"
          step: ->
            element.text formatNumberWithCommaDelimiter(@counter)
            return
        return
  return

$ ->
  metricsInview = new (Waypoint.Inview)(
    element: $('.metric-box')[0]
    enter: (direction) ->
      $(".metric-box strong").each (index) ->
        $target_count = parseInt($(this).text().replace(/\,/g, ''))
        animateNumber($(this), $target_count, 300 + index * 200) if $target_count > 0
      # only run this once
      this.destroy()
  )
