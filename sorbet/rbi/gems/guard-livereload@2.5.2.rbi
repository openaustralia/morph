# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `guard-livereload` gem.
# Please instead update this file by running `bin/tapioca gem guard-livereload`.

# NOTE: Do NOT require "guard/plugin" - it will either be already required, or
# a stub will be supplied by the test class
#
# source://guard-livereload-2.5.2/lib/guard/livereload.rb:3
module Guard
  class << self
    # source://guard-2.18.0/lib/guard.rb:87
    def async_queue_add(changes); end

    # source://guard-2.18.0/lib/guard.rb:73
    def init(cmdline_options); end

    # source://guard-2.18.0/lib/guard.rb:24
    def interactor; end

    # source://guard-2.18.0/lib/guard.rb:23
    def listener; end

    # source://guard-2.18.0/lib/guard.rb:22
    def queue; end

    # source://guard-2.18.0/lib/guard.rb:44
    def setup(cmdline_options = T.unsafe(nil)); end

    # source://guard-2.18.0/lib/guard.rb:21
    def state; end

    private

    # source://guard-2.18.0/lib/guard.rb:132
    def _evaluate(options); end

    # source://guard-2.18.0/lib/guard.rb:152
    def _guardfile_deprecated_check(modified); end

    # source://guard-2.18.0/lib/guard.rb:113
    def _listener_callback; end

    # source://guard-2.18.0/lib/guard.rb:128
    def _pluginless_guardfile?; end

    # source://guard-2.18.0/lib/guard.rb:109
    def _relative_pathnames(paths); end

    # source://guard-2.18.0/lib/guard.rb:99
    def _relevant_changes?(changes); end
  end
end

# source://guard-livereload-2.5.2/lib/guard/livereload.rb:4
class Guard::LiveReload < ::Guard::Plugin
  # @return [LiveReload] a new instance of LiveReload
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:11
  def initialize(options = T.unsafe(nil)); end

  # Returns the value of attribute options.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:9
  def options; end

  # Sets the attribute options
  #
  # @param value the value to set the attribute options to.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:9
  def options=(_arg0); end

  # Returns the value of attribute reactor.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:9
  def reactor; end

  # Sets the attribute reactor
  #
  # @param value the value to set the attribute reactor to.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:9
  def reactor=(_arg0); end

  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:39
  def run_on_modifications(paths); end

  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:31
  def start; end

  # source://guard-livereload-2.5.2/lib/guard/livereload.rb:35
  def stop; end
end

# source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:5
class Guard::LiveReload::Reactor
  # @return [Reactor] a new instance of Reactor
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:8
  def initialize(options); end

  # Returns the value of attribute connections_count.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:6
  def connections_count; end

  # Returns the value of attribute options.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:6
  def options; end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:19
  def reload_browser(paths = T.unsafe(nil)); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:15
  def stop; end

  # Returns the value of attribute thread.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:6
  def thread; end

  # Returns the value of attribute web_sockets.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:6
  def web_sockets; end

  private

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:65
  def _connect(ws); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:35
  def _data(path); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:80
  def _disconnect(ws); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:84
  def _print_message(message); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/reactor.rb:47
  def _start_reactor; end
end

# source://guard-livereload-2.5.2/lib/guard/livereload/snippet.rb:8
class Guard::LiveReload::Snippet
  # @return [Snippet] a new instance of Snippet
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/snippet.rb:12
  def initialize(template, options); end

  # Returns the value of attribute options.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/snippet.rb:10
  def options; end

  # Returns the value of attribute path.
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/snippet.rb:9
  def path; end
end

# source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:8
class Guard::LiveReload::WebSocket < ::EventMachine::WebSocket::Connection
  # @return [WebSocket] a new instance of WebSocket
  #
  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:12
  def initialize(options); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:17
  def dispatch(data); end

  private

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:46
  def _content_type(path); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:58
  def _livereload_js_path; end

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:69
  def _readable_file(path); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:62
  def _serve(path); end

  # source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:32
  def _serve_file(path); end
end

# source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:9
Guard::LiveReload::WebSocket::HTTP_DATA_FORBIDDEN = T.let(T.unsafe(nil), String)

# source://guard-livereload-2.5.2/lib/guard/livereload/websocket.rb:10
Guard::LiveReload::WebSocket::HTTP_DATA_NOT_FOUND = T.let(T.unsafe(nil), String)
