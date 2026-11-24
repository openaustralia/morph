# typed: strict
# frozen_string_literal: true

# Handling of Postal's delivery webhooks: PostalController receives them, SigningKeys checks the signature and BounceRule
# decides which failures say the address is bad.
module PostalWebhook
  # The only mail we tag, set in AlertMailer. Discourse mail from the same mail server is untagged.
  ALERT_TAG = "alert"
end
