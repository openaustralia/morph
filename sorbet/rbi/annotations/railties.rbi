# typed: strong

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

module Rails
  class << self
    sig { returns(Rails::Application) }
    def application; end

    sig { returns(ActiveSupport::BacktraceCleaner) }
    def backtrace_cleaner; end

    sig { returns(ActiveSupport::Cache::Store) }
    def cache; end

    sig { returns(ActiveSupport::EnvironmentInquirer) }
    def env; end

    sig { returns(ActiveSupport::Logger) }
    def logger; end

    sig { returns(Pathname) }
    def root; end

    sig { returns(String) }
    def version; end
  end
end

class Rails::Application < ::Rails::Engine
  sig { returns(Rails::Application::Configuration) }
  def config; end
end

module Rails::Command::Behavior
  mixes_in_class_methods ::Rails::Command::Behavior::ClassMethods
end

class Rails::Engine < ::Rails::Railtie
  sig { returns(ActionDispatch::Routing::RouteSet) }
  def routes(&block); end
end

module Rails::Generators::Migration
  mixes_in_class_methods ::Rails::Generators::Migration::ClassMethods
end

module Rails::Initializable
  mixes_in_class_methods ::Rails::Initializable::ClassMethods
end

class Rails::Railtie
  sig { params(block: T.proc.bind(Rails::Railtie).void).void }
  def configure(&block); end
end
