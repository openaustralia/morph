# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `cookiejar` gem.
# Please instead update this file by running `bin/tapioca gem cookiejar`.

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:5
module CookieJar; end

# Cookie is an immutable object which defines the data model of a HTTP Cookie.
# The data values within the cookie may be different from the
# values described in the literal cookie declaration.
# Specifically, the 'domain' and 'path' values may be set to defaults
# based on the requested resource that resulted in the cookie being set.
#
# source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:11
class CookieJar::Cookie
  # Call {from_set_cookie} to create a new Cookie instance
  #
  # @return [Cookie] a new instance of Cookie
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:241
  def initialize(args); end

  # [String] RFC 2965 field for indicating comment (or a location)
  # describing the cookie to a usesr agent.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:43
  def comment; end

  # [String] RFC 2965 field for indicating comment (or a location)
  # describing the cookie to a usesr agent.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:43
  def comment_url; end

  # [Time] Time when this cookie was first evaluated and created.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:51
  def created_at; end

  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:192
  def decoded_value; end

  # [Boolean] RFC 2965 field for indicating session lifetime for a cookie
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:45
  def discard; end

  # [String] The domain scope of the cookie. Follows the RFC 2965
  # 'effective host' rules. A 'dot' prefix indicates that it applies both
  # to the non-dotted domain and child domains, while no prefix indicates
  # that only exact matches of the domain are in scope.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:21
  def domain; end

  # Indicates whether the cookie is currently considered valid
  #
  # @param time [Time] to compare against, or 'now' if omitted
  # @return [Boolean]
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:69
  def expired?(time = T.unsafe(nil)); end

  # Evaluate when this cookie will expire. Uses the original cookie fields
  # for a max age or expires
  #
  # @return [Time, nil] Time of expiry, if this cookie has an expiry set
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:57
  def expires_at; end

  # [Boolean] Popular browser extension to mark a cookie as invisible
  # to code running within the browser, such as JavaScript
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:35
  def http_only; end

  # [String] The name of the cookie.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:13
  def name; end

  # [String] The path scope of the cookie. The cookie applies to URI paths
  # that prefix match this value.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:25
  def path; end

  # [Array<FixNum>, nil] RFC 2965 port scope for the cookie. If not nil,
  # indicates specific ports on the HTTP server which should receive this
  # cookie if contacted.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:49
  def ports; end

  # [Boolean] The secure flag is set to indicate that the cookie should
  # only be sent securely. Nearly all HTTP User Agent implementations assume
  # this to mean that the cookie should only be sent over a
  # SSL/TLS-protected connection
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:31
  def secure; end

  # Indicates whether the cookie will be considered invalid after the end
  # of the current user session
  #
  # @return [Boolean]
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:76
  def session?; end

  # Determine if a cookie should be sent given a request URI along with
  # other options.
  #
  # This currently ignores domain.
  #
  # this cookie
  # extension should be ignored
  #
  # @param uri [String, URI] the requested page which may need to receive
  # @param script [Boolean] indicates that cookies with the 'httponly'
  # @return [Boolean] whether this cookie should be sent to the server
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:174
  def should_send?(request_uri, script); end

  # Return a hash representation of the cookie.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:140
  def to_hash; end

  # Return a JSON 'object' for the various data values. Allows for
  # persistence of the cookie information
  #
  # @param a [Array] options controlling output JSON text
  #   (usually a State and a depth)
  # @return [String] JSON representation of object data
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:202
  def to_json(*a); end

  # Returns cookie in a format appropriate to send to a server.
  #
  # "$Version=<version>;". Ignored for Netscape-style cookies
  #
  # @param 0 [FixNum] version, 0 for Netscape-style cookies, 1 for
  #   RFC2965-style.
  # @param true [Boolean] prefix, for RFC2965, whether to prefix with
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:126
  def to_s(ver = T.unsafe(nil), prefix = T.unsafe(nil)); end

  # [String] The value of the cookie, without any attempts at decoding.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:15
  def value; end

  # [Fixnum] Version indicator, currently either
  # * 0 for netscape cookies
  # * 1 for RFC 2965 cookies
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:40
  def version; end

  class << self
    # Compute the cookie search domains for a given request URI
    # This will be the effective host of the request uri, along with any
    # possibly matching dot-prefixed domains
    #
    # @param request_uri [String, URI] address being requested
    # @return [Array<String>] String domain matches
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:234
    def compute_search_domains(request_uri); end

    # Create a cookie based on an absolute URI and the string value of a
    # 'Set-Cookie' header.
    #
    # This is used to fill in domain and port if missing from the cookie,
    # and to perform appropriate validation.
    #
    # @param request_uri [String, URI] HTTP/HTTPS absolute URI of request.
    # @param set_cookie_value [String] HTTP value for the Set-Cookie header.
    # @raise [InvalidCookieError] on validation failure(s)
    # @return [Cookie] created from the header string and request URI
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:89
    def from_set_cookie(request_uri, set_cookie_value); end

    # Create a cookie based on an absolute URI and the string value of a
    # 'Set-Cookie2' header.
    #
    # This is used to fill in domain and port if missing from the cookie,
    # and to perform appropriate validation.
    #
    # @param request_uri [String, URI] HTTP/HTTPS absolute URI of request.
    # @param set_cookie_value [String] HTTP value for the Set-Cookie2 header.
    # @raise [InvalidCookieError] on validation failure(s)
    # @return [Cookie] created from the header string and request URI
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:109
    def from_set_cookie2(request_uri, set_cookie_value); end

    # Given a Hash representation of a JSON document, create a local cookie
    # from the included data.
    #
    # @param o [Hash] JSON object of array data
    # @return [Cookie] cookie formed from JSON data
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie.rb:211
    def json_create(o); end
  end
end

# Contains logic to parse and validate cookie headers
#
# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:25
module CookieJar::CookieValidation
  class << self
    # Given a URI, compute the relevant search domains for pre-existing
    # cookies. This includes all the valid dotted forms for a named or IP
    # domains.
    #
    # @param request_uri [String, URI] requested uri
    # @return [Array<String>] all cookie domain values which would match the
    #   requested uri
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:148
    def compute_search_domains(request_uri); end

    # Given a host, compute the relevant search domains for pre-existing
    # cookies
    #
    # @param host [String] host being requested
    # @return [Array<String>] all cookie domain values which would match the
    #   requested uri
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:161
    def compute_search_domains_for_host(host); end

    # Compute the base of a path, for default cookie path assignment
    #
    # @param path, [String, URI, Cookie] or object holding path
    # @return base path (all characters up to final '/')
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:117
    def cookie_base_path(path); end

    # Attempt to decipher a partially decoded version of text cookie values
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:344
    def decode_value(value); end

    # Processes cookie domain data using the following rules:
    # Domains strings of the form .foo.com match 'foo.com' and all immediate
    # subdomains of 'foo.com'. Domain strings specified of the form 'foo.com'
    # are modified to '.foo.com', and as such will still apply to subdomains.
    #
    # Cookies without an explicit domain will have their domain value taken
    # directly from the URL, and will _NOT_ have any leading dot applied. For
    # example, a request to http://foo.com/ will cause an entry for 'foo.com'
    # to be created - which applies to foo.com but no subdomain.
    #
    # Note that this will not attempt to detect a mismatch of the request uri
    # domain and explicitly specified cookie domain
    #
    # @param request_uri [String, URI] originally requested URI
    # @param cookie [String] domain value
    # @return [String] effective host
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:188
    def determine_cookie_domain(request_uri, cookie_domain); end

    # Processes cookie path data using the following rules:
    # Paths are separated by '/' characters, and accepted values are truncated
    # to the last '/' character. If no path is specified in the cookie, a path
    # value will be taken from the request URI which was used for the site.
    #
    # Note that this will not attempt to detect a mismatch of the request uri
    # domain and explicitly specified cookie path
    #
    # @param request [String, URI] URI yielding this cookie
    # @param path [String] on cookie
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:131
    def determine_cookie_path(request_uri, cookie_path); end

    # Compare a tested domain against the base domain to see if they match, or
    # if the base domain is reachable.
    #
    # @param tested_domain [String] domain to be tested against
    # @param base_domain [String] new domain being tested
    # @return [String, nil] matching domain on success, nil on failure
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:93
    def domains_match(tested_domain, base_domain); end

    # Compute the effective host (RFC 2965, section 1)
    #
    # Has the added additional logic of searching for interior dots
    # specifically, and matches colons to prevent .local being suffixed on
    # IPv6 addresses
    #
    # @param host_or_uridomain [String, URI] name, or absolute URI
    # @return [String] effective host per RFC rules
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:209
    def effective_host(host_or_uri); end

    # Compute the reach of a hostname (RFC 2965, section 1)
    # Determines the next highest superdomain
    #
    # @param hostname [String, URI, Cookie] hostname, or object holding hostname
    # @return [String, nil] next highest hostname, or nil if none
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:106
    def hostname_reach(hostname); end

    # Break apart a traditional (non RFC 2965) cookie value into its core
    # components. This does not do any validation, or defaulting of values
    # based on requested URI
    #
    # @param set_cookie_value [String] a Set-Cookie header formatted cookie
    #   definition
    # @return [Hash] Contains the parsed values of the cookie
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:290
    def parse_set_cookie(set_cookie_value); end

    # Break apart a RFC 2965 cookie value into its core components.
    # This does not do any validation, or defaulting of values
    # based on requested URI
    #
    # @param set_cookie_value [String] a Set-Cookie2 header formatted cookie
    #   definition
    # @return [Hash] Contains the parsed values of the cookie
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:359
    def parse_set_cookie2(set_cookie_value); end

    # Converts an input cookie or uri to a string representing the domain.
    # Assume strings are already domains. Value may not be an effective host.
    #
    # @param object [String, URI, Cookie] containing the domain
    # @return [String] domain information.
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:77
    def to_domain(uri_or_domain); end

    # Converts an input cookie or uri to a string representing the path.
    # Assume strings are already paths
    #
    # @param object [String, URI, Cookie] containing the path
    # @return [String] path information
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:64
    def to_path(uri_or_path); end

    # Converts the input object to a URI (if not already a URI)
    #
    # @param request_uri [String, URI] URI we are normalizing
    # @param URI [URI] representation of input string, or original URI
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:55
    def to_uri(request_uri); end

    # Check whether a cookie meets all of the rules to be created, based on
    # its internal settings and the URI it came from.
    #
    # @param request_uri [String, URI] originally requested URI
    # @param cookie [Cookie] object
    # @param will [true] always return true on success
    # @raise [InvalidCookieError] on failures, containing all validation errors
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:227
    def validate_cookie(request_uri, cookie); end

    # Parse a RFC 2965 value and convert to a literal string
    #
    # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:334
    def value_to_string(value); end
  end
end

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:42
CookieJar::CookieValidation::BASE_HOSTNAME = T.let(T.unsafe(nil), Regexp)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:43
CookieJar::CookieValidation::BASE_PATH = T.let(T.unsafe(nil), Regexp)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:45
CookieJar::CookieValidation::HDN = T.let(T.unsafe(nil), Regexp)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:44
CookieJar::CookieValidation::IPADDR = T.let(T.unsafe(nil), Regexp)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:47
CookieJar::CookieValidation::PARAM1 = T.let(T.unsafe(nil), Regexp)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:48
CookieJar::CookieValidation::PARAM2 = T.let(T.unsafe(nil), Regexp)

# REGEX cookie matching
#
# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:27
module CookieJar::CookieValidation::PATTERN
  include ::URI::RFC2396_REGEXP::PATTERN
end

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:33
CookieJar::CookieValidation::PATTERN::BASE_HOSTNAME = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:32
CookieJar::CookieValidation::PATTERN::IPADDR = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:36
CookieJar::CookieValidation::PATTERN::LWS = T.let(T.unsafe(nil), String)

# TEXT="[\\t\\x20-\\x7E\\x80-\\xFF]|(?:#{LWS})"
#
# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:38
CookieJar::CookieValidation::PATTERN::QDTEXT = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:35
CookieJar::CookieValidation::PATTERN::QUOTED_PAIR = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:39
CookieJar::CookieValidation::PATTERN::QUOTED_TEXT = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:30
CookieJar::CookieValidation::PATTERN::TOKEN = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:31
CookieJar::CookieValidation::PATTERN::VALUE1 = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:40
CookieJar::CookieValidation::PATTERN::VALUE2 = T.let(T.unsafe(nil), String)

# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:46
CookieJar::CookieValidation::TOKEN = T.let(T.unsafe(nil), Regexp)

# Represents a set of cookie validation errors
#
# source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:8
class CookieJar::InvalidCookieError < ::StandardError
  # Create a new instance
  #
  # @param the [String, Array<String>] validation issue(s) encountered
  # @return [InvalidCookieError] a new instance of InvalidCookieError
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:13
  def initialize(message); end

  # [Array<String>] the specific validation issues encountered
  #
  # source://cookiejar-0.3.3/lib/cookiejar/cookie_validation.rb:9
  def messages; end
end

# A cookie store for client side usage.
# - Enforces cookie validity rules
# - Returns just the cookies valid for a given URI
# - Handles expiration of cookies
# - Allows for persistence of cookie data (with or without session)
#
# --
#
# Internal format:
#
# Internally, the data structure is a set of nested hashes.
# Domain Level:
# At the domain level, the hashes are of individual domains,
# down-cased and without any leading period. For instance, imagine cookies
# for .foo.com, .bar.com, and .auth.bar.com:
#
#   {
#     "foo.com"      : (host data),
#     "bar.com"      : (host data),
#     "auth.bar.com" : (host data)
#   }
#
# Lookups are done both for the matching entry, and for an entry without
# the first segment up to the dot, ie. for /^\.?[^\.]+\.(.*)$/.
# A lookup of auth.bar.com would match both bar.com and
# auth.bar.com, but not entries for com or www.auth.bar.com.
#
# Host Level:
# Entries are in an hash, with keys of the path and values of a hash of
# cookie names to cookie object
#
#   {
#     "/" : {"session" : (Cookie object), "cart_id" : (Cookie object)}
#     "/protected" : {"authentication" : (Cookie Object)}
#   }
#
# Paths are given a straight prefix string comparison to match.
# Further filters <secure, http only, ports> are not represented in this
# heirarchy.
#
# Cookies returned are ordered solely by specificity (length) of the
# path.
#
# source://cookiejar-0.3.3/lib/cookiejar/jar.rb:46
class CookieJar::Jar
  # Create a new empty Jar
  #
  # @return [Jar] a new instance of Jar
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:48
  def initialize; end

  # Add a pre-existing cookie object to the jar.
  #
  # @param cookie [Cookie] a pre-existing cookie object
  # @return [Cookie] the cookie added to the store
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:126
  def add_cookie(cookie); end

  # Look through the jar for any cookies which have passed their expiration
  # date, or session cookies from a previous session
  #
  # @param session [Boolean] whether session cookies should be expired,
  #   or just cookies past their expiration date.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:191
  def expire_cookies(session = T.unsafe(nil)); end

  # Given a request URI, return a string Cookie header.Cookies will be in
  # order per RFC 2965 - sorted by longest path length, but otherwise
  # unordered.
  #
  # @option opts
  # @param request_uri [String, URI] the address the HTTP request will be
  #   sent to
  # @param opts [Hash] options controlling returned cookies
  # @return String value of the Cookie header which should be sent on the
  #   HTTP request
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:254
  def get_cookie_header(request_uri, opts = T.unsafe(nil)); end

  # Given a request URI, return a sorted list of Cookie objects. Cookies
  # will be in order per RFC 2965 - sorted by longest path length, but
  # otherwise unordered.
  #
  # @option opts
  # @param request_uri [String, URI] the address the HTTP request will be
  #   sent to. This must be a full URI, i.e. must include the protocol,
  #   if you pass digi.ninja it will fail to find the domain, you must pass
  #   http://digi.ninja
  # @param opts [Hash] options controlling returned cookies
  # @return [Array<Cookie>] cookies which should be sent in the HTTP request
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:215
  def get_cookies(request_uri, opts = T.unsafe(nil)); end

  # Given a request URI and a literal Set-Cookie header value, attempt to
  # add the cookie(s) to the cookie store.
  #
  # @param request_uri [String, URI] the resource returning the header
  # @param cookie_header_value [String] the contents of the Set-Cookie
  # @raise [InvalidCookieError] if the cookie header did not validate
  # @return [Cookie] which was created and stored
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:59
  def set_cookie(request_uri, cookie_header_values); end

  # Given a request URI and a literal Set-Cookie2 header value, attempt to
  # add the cookie to the cookie store.
  #
  # @param request_uri [String, URI] the resource returning the header
  # @param cookie_header_value [String] the contents of the Set-Cookie2
  # @raise [InvalidCookieError] if the cookie header did not validate
  # @return [Cookie] which was created and stored
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:73
  def set_cookie2(request_uri, cookie_header_value); end

  # Given a request URI and some HTTP headers, attempt to add the cookie(s)
  # (from Set-Cookie or Set-Cookie2 headers) to the cookie store. If a
  # cookie is defined (by equivalent name, domain, and path) via Set-Cookie
  # and Set-Cookie2, the Set-Cookie version is ignored.
  #
  # @param request_uri [String, URI] the resource returning the header
  # @param http_headers [Hash<String,[String,Array<String>]>] a Hash
  #   which may have a key of "Set-Cookie" or "Set-Cookie2", and values of
  #   either strings or arrays of strings
  # @raise [InvalidCookieError] if one of the cookie headers contained
  #   invalid formatting or data
  # @return [Array<Cookie>, nil] the cookies created, or nil if none found.
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:90
  def set_cookies_from_headers(request_uri, http_headers); end

  # Return an array of all cookie objects in the jar
  #
  # which have not yet been removed with expire_cookies
  #
  # @return [Array<Cookie>] all cookies. Includes any expired cookies
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:136
  def to_a; end

  # Return a JSON 'object' for the various data values. Allows for
  # persistence of the cookie information
  #
  # @param a [Array] options controlling output JSON text
  #   (usually a State and a depth)
  # @return [String] JSON representation of object data
  #
  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:152
  def to_json(*a); end

  protected

  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:309
  def add_cookie_to_path(paths, cookie); end

  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:301
  def find_domain(host); end

  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:305
  def find_or_add_domain_for_cookie(cookie); end

  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:285
  def gather_header_values(http_header_value, &_block); end

  # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:297
  def to_uri(request_uri); end

  class << self
    # Create a new Jar from an array of Cookie objects. Expired cookies
    # will still be added to the archive, and conflicting cookies will
    # be overwritten by the last cookie in the array.
    #
    # @param cookies [Array<Cookie>] array of cookie objects
    # @return [CookieJar] a new CookieJar instance
    #
    # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:178
    def from_a(cookies); end

    # Create a new Jar from a JSON-backed hash
    #
    # @param o [Hash] the expanded JSON object
    # @return [CookieJar] a new CookieJar instance
    #
    # source://cookiejar-0.3.3/lib/cookiejar/jar.rb:163
    def json_create(o); end
  end
end

# source://cookiejar-0.3.3/lib/cookiejar/version.rb:3
CookieJar::VERSION = T.let(T.unsafe(nil), String)
