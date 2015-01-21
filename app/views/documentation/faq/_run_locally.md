First, check you have Ruby 1.9 or greater installed,

    ruby -v
    
If you need to install or update Ruby [see the instructions at ruby-lang.org](https://www.ruby-lang.org/en/documentation/installation/).

Then install [morph command line](https://github.com/openaustralia/morph-cli) gem,

    gem install morph-cli

To run a scraper go to the directory you have your scraper code in and

    morph

It will run your local scraper on the Morph server and stream the console output back to you. You can use this with any support scraper
language without the hassle of having to install lots of things.
