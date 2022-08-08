# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rack-livereload` gem.
# Please instead update this file by running `bin/tapioca gem rack-livereload`.

# source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:3
module Rack
  class << self
    # source://rack-2.2.4/lib/rack/version.rb:26
    def release; end

    # source://rack-2.2.4/lib/rack/version.rb:19
    def version; end
  end
end

# source://rack-2.2.4/lib/rack.rb:29
Rack::CACHE_CONTROL = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:31
Rack::CONTENT_LENGTH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:32
Rack::CONTENT_TYPE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:43
Rack::DELETE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:36
Rack::ETAG = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:30
Rack::EXPIRES = T.let(T.unsafe(nil), String)

Rack::File = Rack::Files

# source://rack-2.2.4/lib/rack.rb:39
Rack::GET = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:44
Rack::HEAD = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:20
Rack::HTTPS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:35
Rack::HTTP_COOKIE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:17
Rack::HTTP_HOST = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:18
Rack::HTTP_PORT = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:19
Rack::HTTP_VERSION = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:46
Rack::LINK = T.let(T.unsafe(nil), String)

# source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:4
class Rack::LiveReload
  # @return [LiveReload] a new instance of LiveReload
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload.rb:9
  def initialize(app, options = T.unsafe(nil)); end

  # source://rack-livereload-0.3.17/lib/rack/livereload.rb:17
  def _call(env); end

  # Returns the value of attribute app.
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload.rb:7
  def app; end

  # source://rack-livereload-0.3.17/lib/rack/livereload.rb:13
  def call(env); end

  private

  # source://rack-livereload-0.3.17/lib/rack/livereload.rb:41
  def deliver_file(file); end
end

# source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:5
class Rack::LiveReload::BodyProcessor
  # @return [BodyProcessor] a new instance of BodyProcessor
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:20
  def initialize(body, options); end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:88
  def app_root; end

  # Returns the value of attribute content_length.
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:10
  def content_length; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:27
  def force_swf?; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:92
  def host_to_use; end

  # Returns the value of attribute livereload_added.
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:10
  def livereload_added; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:16
  def livereload_local_uri; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:100
  def livereload_source; end

  # Returns the value of attribute new_body.
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:10
  def new_body; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:67
  def process!(env); end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:63
  def processed?; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:12
  def protocol; end

  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:96
  def template; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:35
  def use_vendored?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:31
  def with_swf?; end
end

# source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:7
Rack::LiveReload::BodyProcessor::HEAD_TAG_REGEX = T.let(T.unsafe(nil), Regexp)

# source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:6
Rack::LiveReload::BodyProcessor::LIVERELOAD_JS_PATH = T.let(T.unsafe(nil), String)

# source://rack-livereload-0.3.17/lib/rack/livereload/body_processor.rb:8
Rack::LiveReload::BodyProcessor::LIVERELOAD_PORT = T.let(T.unsafe(nil), Integer)

# source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:5
class Rack::LiveReload::ProcessingSkipAnalyzer
  # @return [ProcessingSkipAnalyzer] a new instance of ProcessingSkipAnalyzer
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:12
  def initialize(result, env, options); end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:35
  def bad_browser?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:22
  def chunked?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:43
  def get?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:39
  def html?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:30
  def ignored?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:26
  def inline?; end

  # @return [Boolean]
  #
  # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:18
  def skip_processing?; end

  class << self
    # @return [Boolean]
    #
    # source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:8
    def skip_processing?(result, env, options); end
  end
end

# source://rack-livereload-0.3.17/lib/rack/livereload/processing_skip_analyzer.rb:6
Rack::LiveReload::ProcessingSkipAnalyzer::BAD_USER_AGENTS = T.let(T.unsafe(nil), Array)

# source://rack-livereload-0.3.17/lib/rack-livereload.rb:4
Rack::LiveReload::VERSION = T.let(T.unsafe(nil), String)

# source://rack-test-2.0.2/lib/rack/test.rb:413
Rack::MockSession = Rack::Test::Session

# source://rack-2.2.4/lib/rack.rb:45
Rack::OPTIONS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:42
Rack::PATCH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:21
Rack::PATH_INFO = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:40
Rack::POST = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:41
Rack::PUT = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:25
Rack::QUERY_STRING = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:53
Rack::RACK_ERRORS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:63
Rack::RACK_HIJACK = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:65
Rack::RACK_HIJACK_IO = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:55
Rack::RACK_INPUT = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:64
Rack::RACK_IS_HIJACK = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:54
Rack::RACK_LOGGER = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:76
Rack::RACK_METHODOVERRIDE_ORIGINAL_METHOD = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:67
Rack::RACK_MULTIPART_BUFFER_SIZE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:68
Rack::RACK_MULTIPART_TEMPFILE_FACTORY = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:60
Rack::RACK_MULTIPROCESS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:59
Rack::RACK_MULTITHREAD = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:66
Rack::RACK_RECURSIVE_INCLUDE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:72
Rack::RACK_REQUEST_COOKIE_HASH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:73
Rack::RACK_REQUEST_COOKIE_STRING = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:70
Rack::RACK_REQUEST_FORM_HASH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:69
Rack::RACK_REQUEST_FORM_INPUT = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:71
Rack::RACK_REQUEST_FORM_VARS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:74
Rack::RACK_REQUEST_QUERY_HASH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:75
Rack::RACK_REQUEST_QUERY_STRING = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:61
Rack::RACK_RUNONCE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:56
Rack::RACK_SESSION = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:57
Rack::RACK_SESSION_OPTIONS = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:77
Rack::RACK_SESSION_UNPACKED_COOKIE_DATA = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:58
Rack::RACK_SHOWSTATUS_DETAIL = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:52
Rack::RACK_TEMPFILES = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:62
Rack::RACK_URL_SCHEME = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:51
Rack::RACK_VERSION = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack/version.rb:23
Rack::RELEASE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:22
Rack::REQUEST_METHOD = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:23
Rack::REQUEST_PATH = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:24
Rack::SCRIPT_NAME = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:27
Rack::SERVER_NAME = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:28
Rack::SERVER_PORT = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:26
Rack::SERVER_PROTOCOL = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:33
Rack::SET_COOKIE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:48
Rack::TRACE = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:34
Rack::TRANSFER_ENCODING = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack.rb:47
Rack::UNLINK = T.let(T.unsafe(nil), String)

# source://rack-2.2.4/lib/rack/version.rb:16
Rack::VERSION = T.let(T.unsafe(nil), Array)