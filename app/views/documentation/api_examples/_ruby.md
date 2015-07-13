To your `Gemfile` add

<pre>
gem 'rest-client'
gem 'json'
</pre>

Then run `bundle install`.

<pre>
# Get data from the morph.io api
require 'rest-client'
require 'json'

morph_api_url = 'http://127.0.0.1:3000/morph-test-scrapers/test-ruby/data.json'

# Keep this key secret!
morph_api_key = 'ehOZD8kf1XU0zLRKWhFk'

result = RestClient.get morph_api_url, params:
  {
    key: morph_api_key,
    query: "select * from 'data' limit 10"
  }

p JSON.parse(result)
</pre>
