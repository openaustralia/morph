# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `coffee-rails` gem.
# Please instead update this file by running `bin/tapioca gem coffee-rails`.

# source://coffee-rails-5.0.0/lib/coffee/rails/js_hook.rb:1
module Coffee; end

# source://coffee-rails-5.0.0/lib/coffee/rails/js_hook.rb:2
module Coffee::Rails; end

# source://coffee-rails-5.0.0/lib/coffee/rails/engine.rb:7
class Coffee::Rails::Engine < ::Rails::Engine; end

# source://coffee-rails-5.0.0/lib/coffee/rails/js_hook.rb:3
module Coffee::Rails::JsHook
  extend ::ActiveSupport::Concern
end

# source://coffee-rails-5.0.0/lib/coffee/rails/template_handler.rb:3
class Coffee::Rails::TemplateHandler
  class << self
    # source://coffee-rails-5.0.0/lib/coffee/rails/template_handler.rb:8
    def call(template, source = T.unsafe(nil)); end

    # source://coffee-rails-5.0.0/lib/coffee/rails/template_handler.rb:4
    def erb_handler; end
  end
end

# source://coffee-rails-5.0.0/lib/coffee/rails/version.rb:3
Coffee::Rails::VERSION = T.let(T.unsafe(nil), String)
