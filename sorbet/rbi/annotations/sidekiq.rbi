# typed: ignore

# DO NOT EDIT MANUALLY
# This file was pulled from a central RBI files repository.
# Please run `bin/tapioca annotations` to update it.

class Sidekiq::CLI
  sig { returns(Sidekiq::CLI) }
  def self.instance; end

  sig { returns(Sidekiq::Launcher) }
  def launcher; end
end

class Sidekiq::Client
  def normalize_item(item); end
  def normalized_hash(item_class); end
end

class Sidekiq::DeadSet < ::Sidekiq::JobSet
  Elem = type_member {
  { fixed: Sidekiq::SortedEntry }
}
end

class Sidekiq::JobSet < ::Sidekiq::SortedSet
  Elem = type_member {
  { fixed: Sidekiq::SortedEntry }
}
end

class Sidekiq::Launcher
  sig { returns(T::Boolean) }
  def stopping?; end
end

class Sidekiq::Middleware::Chain
  include ::Enumerable
  Elem = type_member {
  { fixed: T.untyped }
}
end

class Sidekiq::ProcessSet
  include ::Enumerable
  Elem = type_member {
  { fixed: Sidekiq::Process }
}
end

class Sidekiq::Queue
  include ::Enumerable
  Elem = type_member {
  { fixed: Sidekiq::Job }
}

  sig { returns(T::Boolean) }
  def paused?; end

  sig { returns(Integer) }
  def size; end
end

class Sidekiq::RetrySet < ::Sidekiq::JobSet
  Elem = type_member {
  { fixed: Sidekiq::SortedEntry }
}
end

class Sidekiq::ScheduledSet < ::Sidekiq::JobSet
  Elem = type_member {
  { fixed: Sidekiq::SortedEntry }
}
end

class Sidekiq::SortedSet
  include ::Enumerable
  Elem = type_member {
  { fixed: Sidekiq::SortedEntry }
}
end

module Sidekiq::Worker
  mixes_in_class_methods ::Sidekiq::Worker::ClassMethods

  sig { returns(String) }
  def jid; end
end

module Sidekiq::Worker::ClassMethods
  sig { params(args: T.untyped).returns(String) }
  def perform_async(*args); end

  sig { params(interval: T.untyped, args: T.untyped).returns(String) }
  def perform_at(interval, *args); end

  sig { params(interval: T.untyped, args: T.untyped).returns(String) }
  def perform_in(interval, *args); end
end

class Sidekiq::WorkSet
  include ::Enumerable
  Elem = type_member {
  { fixed: T.untyped }
}
end
