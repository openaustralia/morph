# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rails-timeago` gem.
# Please instead update this file by running `bin/tapioca gem rails-timeago`.

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:3
module Rails
  class << self
    # source://railties-5.2.8.1/lib/rails.rb:38
    def app_class; end

    # source://railties-5.2.8.1/lib/rails.rb:38
    def app_class=(_arg0); end

    # source://railties-5.2.8.1/lib/rails.rb:39
    def application; end

    # source://railties-5.2.8.1/lib/rails.rb:37
    def application=(_arg0); end

    # source://railties-5.2.8.1/lib/rails.rb:50
    def backtrace_cleaner; end

    # source://railties-5.2.8.1/lib/rails.rb:38
    def cache; end

    # source://railties-5.2.8.1/lib/rails.rb:38
    def cache=(_arg0); end

    # source://railties-5.2.8.1/lib/rails.rb:46
    def configuration; end

    # source://railties-5.2.8.1/lib/rails.rb:72
    def env; end

    # source://railties-5.2.8.1/lib/rails.rb:79
    def env=(environment); end

    # source://railties-5.2.8.1/lib/rails/gem_version.rb:5
    def gem_version; end

    # source://railties-5.2.8.1/lib/rails.rb:94
    def groups(*groups); end

    # source://railties-5.2.8.1/lib/rails.rb:43
    def initialize!(*args, &block); end

    # source://railties-5.2.8.1/lib/rails.rb:43
    def initialized?(*args, &block); end

    # source://railties-5.2.8.1/lib/rails.rb:38
    def logger; end

    # source://railties-5.2.8.1/lib/rails.rb:38
    def logger=(_arg0); end

    # source://railties-5.2.8.1/lib/rails.rb:110
    def public_path; end

    # source://railties-5.2.8.1/lib/rails.rb:63
    def root; end

    # source://railties-5.2.8.1/lib/rails/version.rb:7
    def version; end
  end
end

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:4
module Rails::Timeago
  class << self
    # Read or write global rails-timeago default options. If no options are
    # given the current defaults will be returned.
    #
    # Available options:
    # [:+nojs+]
    #   Add time ago in words as time tag content instead of absolute time.
    #   (default: false)
    #
    # [:+date_only+]
    #   Only print date as tag content instead of full time.
    #   (default: true)
    #
    # [:+format+]
    #   A time format for localize method used to format static time.
    #   (default: :default)
    #
    # [:+limit+]
    #   Set a limit for time ago tags. All dates before given limit will not
    #   be converted. Global limit should be given as a block to reevaluate
    #   limit each time timeago_tag is called.
    #   (default: proc { 4.days.ago })
    #
    # [:+force+]
    #   Force time ago tag ignoring limit option.
    #   (default: false)
    #
    # [:+default+]
    #   String that will be returned if time is nil.
    #   (default: '-')
    #
    # source://rails-timeago-2.20.0/lib/rails-timeago.rb:52
    def default_options(opts = T.unsafe(nil)); end

    # source://rails-timeago-2.20.0/lib/rails-timeago.rb:67
    def option_hash; end

    # Reset options to default values
    #
    # source://rails-timeago-2.20.0/lib/rails-timeago.rb:63
    def reset_default_options; end
  end
end

# source://rails-timeago-2.20.0/lib/rails-timeago.rb:9
class Rails::Timeago::Engine < ::Rails::Engine; end

# source://rails-timeago-2.20.0/lib/rails-timeago/helper.rb:7
module Rails::Timeago::Helper
  # Return a JavaScript tag to set jQuery timeago locale.
  #
  # source://rails-timeago-2.20.0/lib/rails-timeago/helper.rb:80
  def timeago_script_tag(**kwargs); end

  # Create a time tag usable for jQuery timeago plugin.
  #
  #   timeago_tag Time.zone.now
  #   => "<time datetime="2012-03-10T12:07:07+01:00"
  #             title="Sat, 10 Mar 2012 12:07:07 +0100"
  #             data-time-ago="2012-03-10T12:07:07+01:00">2012-03-10</time>"
  #
  # Available options:
  # [:+nojs+]
  #   Add time ago in words as time tag content instead of absolute time.
  #   (default: false)
  #
  # [:+date_only+]
  #   Only print date as tag content instead of full time.
  #   (default: true)
  #
  # [:+format+]
  #   A time format for localize method used to format static time.
  #   (default: :default)
  #
  # [:+limit+]
  #   Set a limit for time ago tags. All dates before given limit
  #   will not be converted.
  #   (default: 4.days.ago)
  #
  # [:+force+]
  #   Force time ago tag ignoring limit option.
  #   (default: false)
  #
  # [:+default+]
  #   String that will be returned if time is nil.
  #   (default: '-')
  #
  # All other options will be given as options to tag helper.
  #
  # source://rails-timeago-2.20.0/lib/rails-timeago/helper.rb:43
  def timeago_tag(time, html_options = T.unsafe(nil)); end

  # source://rails-timeago-2.20.0/lib/rails-timeago/helper.rb:70
  def timeago_tag_content(time, time_options = T.unsafe(nil)); end
end

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:5
module Rails::Timeago::VERSION
  class << self
    # source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:12
    def to_s; end
  end
end

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:6
Rails::Timeago::VERSION::MAJOR = T.let(T.unsafe(nil), Integer)

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:7
Rails::Timeago::VERSION::MINOR = T.let(T.unsafe(nil), Integer)

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:8
Rails::Timeago::VERSION::PATCH = T.let(T.unsafe(nil), Integer)

# source://rails-timeago-2.20.0/lib/rails-timeago/version.rb:10
Rails::Timeago::VERSION::STRING = T.let(T.unsafe(nil), String)
