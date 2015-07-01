$ ->
  handler = StripeCheckout.configure
    token: (token) ->
      stripeToken = $("<input type=hidden name=stripeToken />").val(token.id)
      $("#basic-signup-form").append(stripeToken).submit()

  $("#basic-signup-form > button").on "click", (e) ->
    e.preventDefault()
    button = $(this)
    amount = button.attr("data-amount")
    handler.open
      key: button.attr("data-key")
      name: "morph.io"
      description: button.attr("data-description")
      amount: amount
      currency: "AUD"
      email: button.attr("data-email")
      panelLabel: "Signup {{amount}}/mo"
