# typed: false
# frozen_string_literal: true

# Copied from twitter-bootstrap-rails gem https://github.com/seyhunak/twitter-bootstrap-rails/blob/b701e23e91bd2726af5bc669b87f7f34efc96ab1/app/helpers/bootstrap_flash_helper.rb

module BootstrapFlashHelper
  # For sorbet
  # include ActionView::Helpers::TagHelper
  # include Kernel
  # include ActionDispatch::Flash::RequestMethods

  ALERT_TYPES = %i[success info warning danger].freeze unless const_defined?(:ALERT_TYPES)

  def bootstrap_flash(options = {})
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. for devise messages set to nothing in a locale file.
      next if message.blank?

      type = type.to_sym
      type = :success if type == :notice
      type = :danger  if type == :alert
      type = :danger  if type == :error
      next unless ALERT_TYPES.include?(type)

      Array(message).each do |msg|
        text = content_tag(
          :div,
          content_tag(
            :div,
            content_tag(
              :button,
              raw("&times;"),
              :class => "close", "data-dismiss" => "alert"
            ) + msg.html_safe,
            class: "container"
          ),
          class: "alert fade in alert-#{type} #{options[:class]}"
        )
        flash_messages << text if msg
      end
    end
    flash_messages.join("\n").html_safe
  end
end
