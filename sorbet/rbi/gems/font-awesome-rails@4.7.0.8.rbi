# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `font-awesome-rails` gem.
# Please instead update this file by running `bin/tapioca gem font-awesome-rails`.

# source://font-awesome-rails-4.7.0.8/lib/font-awesome-rails/version.rb:1
module FontAwesome; end

# source://font-awesome-rails-4.7.0.8/lib/font-awesome-rails/version.rb:2
module FontAwesome::Rails; end

# source://font-awesome-rails-4.7.0.8/lib/font-awesome-rails/engine.rb:3
class FontAwesome::Rails::Engine < ::Rails::Engine; end

# source://font-awesome-rails-4.7.0.8/lib/font-awesome-rails/version.rb:3
FontAwesome::Rails::FA_VERSION = T.let(T.unsafe(nil), String)

# source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:3
module FontAwesome::Rails::IconHelper
  # source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:32
  def fa_icon(names = T.unsafe(nil), original_options = T.unsafe(nil)); end

  # source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:65
  def fa_stacked_icon(names = T.unsafe(nil), original_options = T.unsafe(nil)); end
end

# source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:80
module FontAwesome::Rails::IconHelper::Private
  extend ::ActionView::Helpers::OutputSafetyHelper

  class << self
    # source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:94
    def array_value(value = T.unsafe(nil)); end

    # source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:83
    def icon_join(icon, text, reverse_order = T.unsafe(nil)); end

    # source://font-awesome-rails-4.7.0.8/app/helpers/font_awesome/rails/icon_helper.rb:90
    def icon_names(names = T.unsafe(nil)); end
  end
end

# source://font-awesome-rails-4.7.0.8/lib/font-awesome-rails/version.rb:4
FontAwesome::Rails::VERSION = T.let(T.unsafe(nil), String)
