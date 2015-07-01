$ ->
  handler = StripeCheckout.configure
    token: (token) ->
      $("#stripeToken").val(token.id)
      $("#supporter-signup-form").submit()

  $("#supporter-signup-form button").on "click", (e) ->
    e.preventDefault()
    button = $(this)
    $("#plan_id").val(button.attr("data-plan-id"))
    amount = button.attr("data-amount")
    handler.open
      key: button.attr("data-key")
      name: "morph.io"
      description: button.attr("data-description")
      amount: amount
      currency: "AUD"
      email: button.attr("data-email")
      panelLabel: "Signup {{amount}}/mo"
