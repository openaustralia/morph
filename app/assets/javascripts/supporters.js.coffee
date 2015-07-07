$ ->
  handler = StripeCheckout.configure
    token: (token) ->
      $("#stripeToken").val(token.id)
      $("#supporter-signup-form").submit()

  $("#supporter-signup-form button").on "click", (e) ->
    e.preventDefault()
    button = $(this)
    $("#plan_id").val(button.attr("data-plan-id"))
    if button.attr("data-stripe") == "true"
      handler.open
        key: button.attr("data-key")
        name: "morph.io"
        description: button.attr("data-description")
        amount: button.attr("data-amount")
        currency: "USD"
        email: button.attr("data-email")
        panelLabel: "Signup USD {{amount}}/mo"
    else
      $("#supporter-signup-form").submit()

  one_time_handler = StripeCheckout.configure
    token: (token) ->
      $("#stripeTokenOneTime").val(token.id)
      $("#supporter-one-time-form").submit()

  $("#supporter-one-time-form button").on "click", (e) ->
    e.preventDefault()
    button = $(this)
    amountInCents = Math.round(parseFloat($('#amount').val()) * 100)
    console.log amountInCents
    one_time_handler.open
      key: button.attr("data-key")
      name: "morph.io"
      description: 'One time contribution'
      amount: amountInCents
      currency: "USD"
      email: button.attr("data-email")
      panelLabel: "Contribute USD {{amount}}"
