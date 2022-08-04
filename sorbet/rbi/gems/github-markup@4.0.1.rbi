# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `github-markup` gem.
# Please instead update this file by running `bin/tapioca gem github-markup`.

# source://github-markup-4.0.1/lib/github/markup/implementation.rb:1
module GitHub; end

# source://github-markup-4.0.1/lib/github/markup/implementation.rb:2
module GitHub::Markup
  extend ::GitHub::Markup

  # @return [Boolean]
  #
  # source://github-markup-4.0.1/lib/github/markup.rb:81
  def can_render?(filename, content, symlink: T.unsafe(nil)); end

  # source://github-markup-4.0.1/lib/github/markup.rb:72
  def command(symbol, command, regexp, languages, name, &block); end

  # source://github-markup-4.0.1/lib/github/markup.rb:92
  def language(filename, content, symlink: T.unsafe(nil)); end

  # source://github-markup-4.0.1/lib/github/markup.rb:60
  def markup(symbol, gem_name, regexp, languages, opts = T.unsafe(nil), &block); end

  # source://github-markup-4.0.1/lib/github/markup.rb:65
  def markup_impl(symbol, impl); end

  # source://github-markup-4.0.1/lib/github/markup.rb:34
  def markup_impls; end

  # source://github-markup-4.0.1/lib/github/markup.rb:30
  def markups; end

  # source://github-markup-4.0.1/lib/github/markup.rb:38
  def preload!; end

  # source://github-markup-4.0.1/lib/github/markup.rb:42
  def render(filename, content, symlink: T.unsafe(nil), options: T.unsafe(nil)); end

  # @raise [ArgumentError]
  #
  # source://github-markup-4.0.1/lib/github/markup.rb:50
  def render_s(symbol, content, options: T.unsafe(nil)); end

  # source://github-markup-4.0.1/lib/github/markup.rb:85
  def renderer(filename, content, symlink: T.unsafe(nil)); end
end

# source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:12
class GitHub::Markup::CommandError < ::RuntimeError; end

# source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:15
class GitHub::Markup::CommandImplementation < ::GitHub::Markup::Implementation
  # @return [CommandImplementation] a new instance of CommandImplementation
  #
  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:18
  def initialize(regexp, languages, command, name, &block); end

  # Returns the value of attribute block.
  #
  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:16
  def block; end

  # Returns the value of attribute command.
  #
  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:16
  def command; end

  # Returns the value of attribute name.
  #
  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:16
  def name; end

  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:25
  def render(filename, content, options: T.unsafe(nil)); end

  private

  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:32
  def call_block(rendered, content); end

  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:43
  def execute(command, target); end

  # source://github-markup-4.0.1/lib/github/markup/command_implementation.rb:66
  def sanitize(input, encoding); end
end

# source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:5
class GitHub::Markup::GemImplementation < ::GitHub::Markup::Implementation
  # @return [GemImplementation] a new instance of GemImplementation
  #
  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:8
  def initialize(regexp, languages, gem_name, &renderer); end

  # Returns the value of attribute gem_name.
  #
  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:6
  def gem_name; end

  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:14
  def load; end

  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:25
  def name; end

  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:20
  def render(filename, content, options: T.unsafe(nil)); end

  # Returns the value of attribute renderer.
  #
  # source://github-markup-4.0.1/lib/github/markup/gem_implementation.rb:6
  def renderer; end
end

# source://github-markup-4.0.1/lib/github/markup/implementation.rb:3
class GitHub::Markup::Implementation
  # @return [Implementation] a new instance of Implementation
  #
  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:7
  def initialize(regexp, languages); end

  # Returns the value of attribute languages.
  #
  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:5
  def languages; end

  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:19
  def load; end

  # @return [Boolean]
  #
  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:27
  def match?(filename, language); end

  # Returns the value of attribute regexp.
  #
  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:4
  def regexp; end

  # @raise [NotImplementedError]
  #
  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:23
  def render(filename, content, options: T.unsafe(nil)); end

  private

  # source://github-markup-4.0.1/lib/github/markup/implementation.rb:37
  def file_ext_regexp; end
end

# source://github-markup-4.0.1/lib/github/markup/markdown.rb:5
class GitHub::Markup::Markdown < ::GitHub::Markup::Implementation
  # @return [Markdown] a new instance of Markdown
  #
  # source://github-markup-4.0.1/lib/github/markup/markdown.rb:32
  def initialize; end

  # @raise [LoadError]
  #
  # source://github-markup-4.0.1/lib/github/markup/markdown.rb:38
  def load; end

  # source://github-markup-4.0.1/lib/github/markup/markdown.rb:54
  def name; end

  # source://github-markup-4.0.1/lib/github/markup/markdown.rb:49
  def render(filename, content, options: T.unsafe(nil)); end

  private

  # source://github-markup-4.0.1/lib/github/markup/markdown.rb:59
  def try_require(file); end
end

# source://github-markup-4.0.1/lib/github/markup/markdown.rb:6
GitHub::Markup::Markdown::MARKDOWN_GEMS = T.let(T.unsafe(nil), Hash)

# source://github-markup-4.0.1/lib/github/markup/rdoc.rb:7
class GitHub::Markup::RDoc < ::GitHub::Markup::Implementation
  # @return [RDoc] a new instance of RDoc
  #
  # source://github-markup-4.0.1/lib/github/markup/rdoc.rb:8
  def initialize; end

  # source://github-markup-4.0.1/lib/github/markup/rdoc.rb:21
  def name; end

  # source://github-markup-4.0.1/lib/github/markup/rdoc.rb:12
  def render(filename, content, options: T.unsafe(nil)); end
end

# source://github-markup-4.0.1/lib/github/markup.rb:11
module GitHub::Markups; end

# all of supported markups:
#
# source://github-markup-4.0.1/lib/github/markup.rb:13
GitHub::Markups::MARKUP_ASCIIDOC = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:14
GitHub::Markups::MARKUP_CREOLE = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:15
GitHub::Markups::MARKUP_MARKDOWN = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:16
GitHub::Markups::MARKUP_MEDIAWIKI = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:17
GitHub::Markups::MARKUP_ORG = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:18
GitHub::Markups::MARKUP_POD = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:22
GitHub::Markups::MARKUP_POD6 = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:19
GitHub::Markups::MARKUP_RDOC = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:20
GitHub::Markups::MARKUP_RST = T.let(T.unsafe(nil), Symbol)

# source://github-markup-4.0.1/lib/github/markup.rb:21
GitHub::Markups::MARKUP_TEXTILE = T.let(T.unsafe(nil), Symbol)
