# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rails_autolink` gem.
# Please instead update this file by running `bin/tapioca gem rails_autolink`.

# Rails 2.0.X (X >= 2)
#
# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:9
module ActionView
  class << self
    # source://actionview-5.2.8.1/lib/action_view.rb:86
    def eager_load!; end

    # Returns the version of the currently loaded Action View as a <tt>Gem::Version</tt>
    #
    # source://actionview-5.2.8.1/lib/action_view/gem_version.rb:5
    def gem_version; end

    # Returns the version of the currently loaded ActionView as a <tt>Gem::Version</tt>
    #
    # source://actionview-5.2.8.1/lib/action_view/version.rb:7
    def version; end
  end
end

# source://actionview-5.2.8.1/lib/action_view.rb:33
ActionView::ENCODING_FLAG = T.let(T.unsafe(nil), String)

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:10
module ActionView::Helpers
  include ::ActionView::Helpers::SanitizeHelper
  include ::ActionView::Helpers::TagHelper
  include ::ActionView::Helpers::TextHelper
  include ::ActionView::Helpers::TagHelper
  include ::ActionView::Helpers::AssetTagHelper
  include ::ActionView::Helpers::UrlHelper
  include ::ActionView::Helpers::SanitizeHelper
  include ::ActionView::Helpers::TextHelper
  include ::ActionView::Helpers::FormTagHelper
  include ::ActionView::Helpers::FormHelper
  include ::ActionView::Helpers::TranslationHelper

  mixes_in_class_methods ::ActionView::Helpers::UrlHelper::ClassMethods
  mixes_in_class_methods ::ActionView::Helpers::SanitizeHelper::ClassMethods

  class << self
    # source://actionview-5.2.8.1/lib/action_view/helpers.rb:35
    def eager_load!; end
  end
end

# The TextHelper module provides a set of methods for filtering, formatting
# and transforming strings, which can reduce the amount of inline Ruby code in
# your views. These helper methods extend Action View making them callable
# within your template files.
#
# ==== Sanitization
#
# Most text helpers that generate HTML output sanitize the given input by default,
# but do not escape it. This means HTML tags will appear in the page but all malicious
# code will be removed. Let's look at some examples using the +simple_format+ method:
#
#   simple_format('<a href="http://example.com/">Example</a>')
#   # => "<p><a href=\"http://example.com/\">Example</a></p>"
#
#   simple_format('<a href="javascript:alert(\'no!\')">Example</a>')
#   # => "<p><a>Example</a></p>"
#
# If you want to escape all content, you should invoke the +h+ method before
# calling the text helper.
#
#   simple_format h('<a href="http://example.com/">Example</a>')
#   # => "<p>&lt;a href=\"http://example.com/\"&gt;Example&lt;/a&gt;</p>"
#
# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:11
module ActionView::Helpers::TextHelper
  include ::ActionView::Helpers::SanitizeHelper
  include ::ActionView::Helpers::TagHelper

  mixes_in_class_methods ::ActionView::Helpers::SanitizeHelper::ClassMethods

  # Turns all URLs and e-mail addresses into clickable links. The <tt>:link</tt> option
  # will limit what should be linked. You can add HTML attributes to the links using
  # <tt>:html</tt>. Possible values for <tt>:link</tt> are <tt>:all</tt> (default),
  # <tt>:email_addresses</tt>, and <tt>:urls</tt>. If a block is given, each URL and
  # e-mail address is yielded and the result is used as the link text. By default the
  # text given is sanitized, you can override this behaviour setting the
  # <tt>:sanitize</tt> option to false, or you can add options to the sanitization of
  # the text using the <tt>:sanitize_options</tt> option hash.
  #
  # ==== Examples
  #   auto_link("Go to http://www.rubyonrails.org and say hello to david@loudthinking.com")
  #   # => "Go to <a href=\"http://www.rubyonrails.org\">http://www.rubyonrails.org</a> and
  #   #     say hello to <a href=\"mailto:david@loudthinking.com\">david@loudthinking.com</a>"
  #
  #   auto_link("Visit http://www.loudthinking.com/ or e-mail david@loudthinking.com", :link => :urls)
  #   # => "Visit <a href=\"http://www.loudthinking.com/\">http://www.loudthinking.com/</a>
  #   #     or e-mail david@loudthinking.com"
  #
  #   auto_link("Visit http://www.loudthinking.com/ or e-mail david@loudthinking.com", :link => :email_addresses)
  #   # => "Visit http://www.loudthinking.com/ or e-mail <a href=\"mailto:david@loudthinking.com\">david@loudthinking.com</a>"
  #
  #   post_body = "Welcome to my new blog at http://www.myblog.com/.  Please e-mail me at me@email.com."
  #   auto_link(post_body, :html => { :target => '_blank' }) do |text|
  #     truncate(text, :length => 15)
  #   end
  #   # => "Welcome to my new blog at <a href=\"http://www.myblog.com/\" target=\"_blank\">http://www.m...</a>.
  #         Please e-mail me at <a href=\"mailto:me@email.com\">me@email.com</a>."
  #
  #
  # You can still use <tt>auto_link</tt> with the old API that accepts the
  # +link+ as its optional second parameter and the +html_options+ hash
  # as its optional third parameter:
  #   post_body = "Welcome to my new blog at http://www.myblog.com/. Please e-mail me at me@email.com."
  #   auto_link(post_body, :urls)
  #   # => "Welcome to my new blog at <a href=\"http://www.myblog.com/\">http://www.myblog.com</a>.
  #         Please e-mail me at me@email.com."
  #
  #   auto_link(post_body, :all, :target => "_blank")
  #   # => "Welcome to my new blog at <a href=\"http://www.myblog.com/\" target=\"_blank\">http://www.myblog.com</a>.
  #         Please e-mail me at <a href=\"mailto:me@email.com\">me@email.com</a>."
  #
  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:52
  def auto_link(text, *args, &block); end

  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:54
  def concat(string); end

  # Returns the current cycle string after a cycle has been started. Useful
  # for complex table highlighting or any other design need which requires
  # the current cycle string in more than one place.
  #
  #   # Alternate background colors
  #   @items = [1,2,3,4]
  #   <% @items.each do |item| %>
  #     <div style="background-color:<%= cycle("red","white","blue") %>">
  #       <span style="background-color:<%= current_cycle %>"><%= item %></span>
  #     </div>
  #   <% end %>
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:378
  def current_cycle(name = T.unsafe(nil)); end

  # Creates a Cycle object whose _to_s_ method cycles through elements of an
  # array every time it is called. This can be used for example, to alternate
  # classes for table rows. You can use named cycles to allow nesting in loops.
  # Passing a Hash as the last parameter with a <tt>:name</tt> key will create a
  # named cycle. The default name for a cycle without a +:name+ key is
  # <tt>"default"</tt>. You can manually reset a cycle by calling reset_cycle
  # and passing the name of the cycle. The current cycle string can be obtained
  # anytime using the current_cycle method.
  #
  #   # Alternate CSS classes for even and odd numbers...
  #   @items = [1,2,3,4]
  #   <table>
  #   <% @items.each do |item| %>
  #     <tr class="<%= cycle("odd", "even") -%>">
  #       <td><%= item %></td>
  #     </tr>
  #   <% end %>
  #   </table>
  #
  #
  #   # Cycle CSS classes for rows, and text colors for values within each row
  #   @items = x = [{first: 'Robert', middle: 'Daniel', last: 'James'},
  #                {first: 'Emily', middle: 'Shannon', maiden: 'Pike', last: 'Hicks'},
  #               {first: 'June', middle: 'Dae', last: 'Jones'}]
  #   <% @items.each do |item| %>
  #     <tr class="<%= cycle("odd", "even", name: "row_class") -%>">
  #       <td>
  #         <% item.values.each do |value| %>
  #           <%# Create a named cycle "colors" %>
  #           <span style="color:<%= cycle("red", "green", "blue", name: "colors") -%>">
  #             <%= value %>
  #           </span>
  #         <% end %>
  #         <% reset_cycle("colors") %>
  #       </td>
  #    </tr>
  #  <% end %>
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:354
  def cycle(first_value, *values); end

  # Extracts an excerpt from +text+ that matches the first instance of +phrase+.
  # The <tt>:radius</tt> option expands the excerpt on each side of the first occurrence of +phrase+ by the number of characters
  # defined in <tt>:radius</tt> (which defaults to 100). If the excerpt radius overflows the beginning or end of the +text+,
  # then the <tt>:omission</tt> option (which defaults to "...") will be prepended/appended accordingly. Use the
  # <tt>:separator</tt> option to choose the delimitation. The resulting string will be stripped in any case. If the +phrase+
  # isn't found, +nil+ is returned.
  #
  #   excerpt('This is an example', 'an', radius: 5)
  #   # => ...s is an exam...
  #
  #   excerpt('This is an example', 'is', radius: 5)
  #   # => This is a...
  #
  #   excerpt('This is an example', 'is')
  #   # => This is an example
  #
  #   excerpt('This next thing is an example', 'ex', radius: 2)
  #   # => ...next...
  #
  #   excerpt('This is also an example', 'an', radius: 8, omission: '<chop> ')
  #   # => <chop> is also an example
  #
  #   excerpt('This is a very beautiful morning', 'very', separator: ' ', radius: 1)
  #   # => ...a very beautiful...
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:175
  def excerpt(text, phrase, options = T.unsafe(nil)); end

  # Highlights one or more +phrases+ everywhere in +text+ by inserting it into
  # a <tt>:highlighter</tt> string. The highlighter can be specialized by passing <tt>:highlighter</tt>
  # as a single-quoted string with <tt>\1</tt> where the phrase is to be inserted (defaults to
  # '<mark>\1</mark>') or passing a block that receives each matched term. By default +text+
  # is sanitized to prevent possible XSS attacks. If the input is trustworthy, passing false
  # for <tt>:sanitize</tt> will turn sanitizing off.
  #
  #   highlight('You searched for: rails', 'rails')
  #   # => You searched for: <mark>rails</mark>
  #
  #   highlight('You searched for: rails', /for|rails/)
  #   # => You searched <mark>for</mark>: <mark>rails</mark>
  #
  #   highlight('You searched for: ruby, rails, dhh', 'actionpack')
  #   # => You searched for: ruby, rails, dhh
  #
  #   highlight('You searched for: rails', ['for', 'rails'], highlighter: '<em>\1</em>')
  #   # => You searched <em>for</em>: <em>rails</em>
  #
  #   highlight('You searched for: rails', 'rails', highlighter: '<a href="search?q=\1">\1</a>')
  #   # => You searched for: <a href="search?q=rails">rails</a>
  #
  #   highlight('You searched for: rails', 'rails') { |match| link_to(search_path(q: match, match)) }
  #   # => You searched for: <a href="search?q=rails">rails</a>
  #
  #   highlight('<a href="javascript:alert(\'no!\')">ruby</a> on rails', 'rails', sanitize: false)
  #   # => <a href="javascript:alert('no!')">ruby</a> on <mark>rails</mark>
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:132
  def highlight(text, phrases, options = T.unsafe(nil)); end

  # Attempts to pluralize the +singular+ word unless +count+ is 1. If
  # +plural+ is supplied, it will use that when count is > 1, otherwise
  # it will use the Inflector to determine the plural form for the given locale,
  # which defaults to I18n.locale
  #
  # The word will be pluralized using rules defined for the locale
  # (you must define your own inflection rules for languages other than English).
  # See ActiveSupport::Inflector.pluralize
  #
  #   pluralize(1, 'person')
  #   # => 1 person
  #
  #   pluralize(2, 'person')
  #   # => 2 people
  #
  #   pluralize(3, 'person', plural: 'users')
  #   # => 3 users
  #
  #   pluralize(0, 'person')
  #   # => 0 people
  #
  #   pluralize(2, 'Person', locale: :de)
  #   # => 2 Personen
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:230
  def pluralize(count, singular, plural_arg = T.unsafe(nil), plural: T.unsafe(nil), locale: T.unsafe(nil)); end

  # Resets a cycle so that it starts from the first element the next time
  # it is called. Pass in +name+ to reset a named cycle.
  #
  #   # Alternate CSS classes for even and odd numbers...
  #   @items = [[1,2,3,4], [5,6,3], [3,4,5,6,7,4]]
  #   <table>
  #   <% @items.each do |item| %>
  #     <tr class="<%= cycle("even", "odd") -%>">
  #         <% item.each do |value| %>
  #           <span style="color:<%= cycle("#333", "#666", "#999", name: "colors") -%>">
  #             <%= value %>
  #           </span>
  #         <% end %>
  #
  #         <% reset_cycle("colors") %>
  #     </tr>
  #   <% end %>
  #   </table>
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:401
  def reset_cycle(name = T.unsafe(nil)); end

  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:58
  def safe_concat(string); end

  # Returns +text+ transformed into HTML using simple formatting rules.
  # Two or more consecutive newlines(<tt>\n\n</tt> or <tt>\r\n\r\n</tt>) are
  # considered a paragraph and wrapped in <tt><p></tt> tags. One newline
  # (<tt>\n</tt> or <tt>\r\n</tt>) is considered a linebreak and a
  # <tt><br /></tt> tag is appended. This method does not remove the
  # newlines from the +text+.
  #
  # You can pass any HTML attributes into <tt>html_options</tt>. These
  # will be added to all created paragraphs.
  #
  # ==== Options
  # * <tt>:sanitize</tt> - If +false+, does not sanitize +text+.
  # * <tt>:wrapper_tag</tt> - String representing the wrapper tag, defaults to <tt>"p"</tt>
  #
  # ==== Examples
  #   my_text = "Here is some basic text...\n...with a line break."
  #
  #   simple_format(my_text)
  #   # => "<p>Here is some basic text...\n<br />...with a line break.</p>"
  #
  #   simple_format(my_text, {}, wrapper_tag: "div")
  #   # => "<div>Here is some basic text...\n<br />...with a line break.</div>"
  #
  #   more_text = "We want to put a paragraph...\n\n...right there."
  #
  #   simple_format(more_text)
  #   # => "<p>We want to put a paragraph...</p>\n\n<p>...right there.</p>"
  #
  #   simple_format("Look ma! A class!", class: 'description')
  #   # => "<p class='description'>Look ma! A class!</p>"
  #
  #   simple_format("<blink>Unblinkable.</blink>")
  #   # => "<p>Unblinkable.</p>"
  #
  #   simple_format("<blink>Blinkable!</blink> It's true.", {}, sanitize: false)
  #   # => "<p><blink>Blinkable!</blink> It's true.</p>"
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:302
  def simple_format(text, html_options = T.unsafe(nil), options = T.unsafe(nil)); end

  # Truncates a given +text+ after a given <tt>:length</tt> if +text+ is longer than <tt>:length</tt>
  # (defaults to 30). The last characters will be replaced with the <tt>:omission</tt> (defaults to "...")
  # for a total length not exceeding <tt>:length</tt>.
  #
  # Pass a <tt>:separator</tt> to truncate +text+ at a natural break.
  #
  # Pass a block if you want to show extra content when the text is truncated.
  #
  # The result is marked as HTML-safe, but it is escaped by default, unless <tt>:escape</tt> is
  # +false+. Care should be taken if +text+ contains HTML tags or entities, because truncation
  # may produce invalid HTML (such as unbalanced or incomplete tags).
  #
  #   truncate("Once upon a time in a world far far away")
  #   # => "Once upon a time in a world..."
  #
  #   truncate("Once upon a time in a world far far away", length: 17)
  #   # => "Once upon a ti..."
  #
  #   truncate("Once upon a time in a world far far away", length: 17, separator: ' ')
  #   # => "Once upon a..."
  #
  #   truncate("And they found that many people were sleeping better.", length: 25, omission: '... (continued)')
  #   # => "And they f... (continued)"
  #
  #   truncate("<p>Once upon a time in a world far far away</p>")
  #   # => "&lt;p&gt;Once upon a time in a wo..."
  #
  #   truncate("<p>Once upon a time in a world far far away</p>", escape: false)
  #   # => "<p>Once upon a time in a wo..."
  #
  #   truncate("Once upon a time in a world far far away") { link_to "Continue", "#" }
  #   # => "Once upon a time in a wo...<a href="#">Continue</a>"
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:94
  def truncate(text, options = T.unsafe(nil), &block); end

  # Wraps the +text+ into lines no longer than +line_width+ width. This method
  # breaks on the first whitespace character that does not exceed +line_width+
  # (which is 80 by default).
  #
  #   word_wrap('Once upon a time')
  #   # => Once upon a time
  #
  #   word_wrap('Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding a successor to the throne turned out to be more trouble than anyone could have imagined...')
  #   # => Once upon a time, in a kingdom called Far Far Away, a king fell ill, and finding\na successor to the throne turned out to be more trouble than anyone could have\nimagined...
  #
  #   word_wrap('Once upon a time', line_width: 8)
  #   # => Once\nupon a\ntime
  #
  #   word_wrap('Once upon a time', line_width: 1)
  #   # => Once\nupon\na\ntime
  #
  #   You can also specify a custom +break_sequence+ ("\n" by default)
  #
  #   word_wrap('Once upon a time', line_width: 1, break_sequence: "\r\n")
  #   # => Once\r\nupon\r\na\r\ntime
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:260
  def word_wrap(text, line_width: T.unsafe(nil), break_sequence: T.unsafe(nil)); end

  private

  # Turns all email addresses into clickable links.  If a block is given,
  # each email is yielded and the result is used as the link text.
  #
  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:123
  def auto_link_email_addresses(text, html_options = T.unsafe(nil), options = T.unsafe(nil)); end

  # Turns all urls into clickable links.  If a block is given, each url
  # is yielded and the result is used as the link text.
  #
  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:90
  def auto_link_urls(text, html_options = T.unsafe(nil), options = T.unsafe(nil)); end

  # Detects already linked context or position in the middle of a tag
  #
  # @return [Boolean]
  #
  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:142
  def auto_linked?(left, right); end

  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:151
  def conditional_html_safe(target, condition); end

  # source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:147
  def conditional_sanitize(target, condition, sanitize_options = T.unsafe(nil)); end

  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:465
  def cut_excerpt_part(part_position, part, separator, options); end

  # The cycle helpers need to store the cycles in a place that is
  # guaranteed to be reset every time a page is rendered, so it
  # uses an instance variable of ActionView::Base.
  #
  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:447
  def get_cycle(name); end

  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:452
  def set_cycle(name, cycle_object); end

  # source://actionview-5.2.8.1/lib/action_view/helpers/text_helper.rb:457
  def split_paragraphs(text); end
end

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:81
ActionView::Helpers::TextHelper::AUTO_EMAIL_LOCAL_RE = T.let(T.unsafe(nil), Regexp)

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:82
ActionView::Helpers::TextHelper::AUTO_EMAIL_RE = T.let(T.unsafe(nil), Regexp)

# regexps for determining context, used high-volume
#
# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:79
ActionView::Helpers::TextHelper::AUTO_LINK_CRE = T.let(T.unsafe(nil), Array)

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:73
ActionView::Helpers::TextHelper::AUTO_LINK_RE = T.let(T.unsafe(nil), Regexp)

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:84
ActionView::Helpers::TextHelper::BRACKETS = T.let(T.unsafe(nil), Hash)

# source://rails_autolink-1.1.6/lib/rails_autolink/helpers.rb:86
ActionView::Helpers::TextHelper::WORD_PATTERN = T.let(T.unsafe(nil), String)

# source://actionview-5.2.8.1/lib/action_view/template/error.rb:140
ActionView::TemplateError = ActionView::Template::Error

# source://rails_autolink-1.1.6/lib/rails_autolink.rb:1
module RailsAutolink; end

# source://rails_autolink-1.1.6/lib/rails_autolink.rb:2
class RailsAutolink::Railtie < ::Rails::Railtie; end
