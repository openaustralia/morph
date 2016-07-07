This folder contains some initial straw-man documentation for the morph server,
a low level scraper api, suggested in
https://github.com/openaustralia/morph/issues/647

Body of the github issue above copied below for ease
of access.

# Reasons to do this

* Scale morph.io by running the user-interface on separate servers from the scraper running. This allows us to scale the number of scrapers that we can run and improve the reliability and security.
* Allow people very easily to use the [command line morph tool](https://github.com/openaustralia/morph-cli) to run a complete morph server locally so that they can test and run their scrapers in a completely identical way as morph.io without having to actually run it on morph.io.
* Creates a reusable component for people that want to do scraping in their project but want to do it differently than the way morph.io does it and don't want to have to build the docker/buildpack infrastructure from scratch themselves.
* Create more innovation in scraper tools by making the low-level scraping infrastructure stuff really easy. After all, morph.io is one of many approaches to scraping that is possible. Let's see more diversity, not less.
* The civic tech/open data/scraping community could potentially donate morph servers that could be added to the pool and made available to everyone through morph.io much in the same way as [travis-ci.org](https://travis-ci.org/)

# It should

* Be much much less opinionated than morph.io as to how scrapers should work
* Have no need to maintain state between scraper runs
* Use [buildstep](https://github.com/openaustralia/buildstep) to allow scrapers to use a choice of languages including being able to install their own libraries easily.
* Be a stand-alone project with its own repository, website and of course a catchy name
* Be licensed MIT to allow commercial reuse
* Be super easy to install
* Record cpu and memory use metrics for the scraper run
* Provide a real-time stream of its console output
* Provide a real-time stream of the urls the scraper scrapes
* Provide an API to run web callbacks when the scraper finishes. This can be used to asynchronously notify a client of a finished scraper and/or upload data of the scraper output.
* Automatic caching of buildstep compiles shared between scrapers and scraper runs
* Enforce a disk-space allocation for docker images

## Be much much less opinionated than morph.io

* Data doesn't need to be stored in SQLite database
* Data could be stored in an external database like MySQL or Postgres
* New data could be sent to standard out as JSON
* Shouldn't depend on the morph.io scraper naming convention. Specifically, scrapers don't need to be called `scraper.rb`, or `scraper.py` depending on the language. Rather than this we use a `scraper` process type in the `Procfile`.
* We don't do any "magic" default insertion for the `Gemfile` or language version. We just use the vanilla buildpack compile.
* We allow all the languages supported by buildstep not just Ruby, Python, PHP and Perl.
* We allow any files which can include any data or code files

## Have no need to maintain state between scraper runs

Currently in morph.io the `/data` directory in each container is mounted to the host filesystem to ensure that the SQLite database for each scraper is persistent. This is currently stopping the docker server from running on a different server to the web app server.

So, for simplicity, what if the necessary data and code is transferred to the container before the run and the result is transferred out of the container at the end of the run? This way, there is little that the morph server needs to know and makes it very easy for anyone to run one. Also, if third parties are running docker servers that morph.io is using we shouldn't be depending on them always being there. If they can dissapear at any time they also can't store information we need.

## Be licensed MIT to allow commercial reuse

This is perhaps an unusual course of action given that [morph.io is licensed under AGPL](https://github.com/openaustralia/morph/blob/master/LICENSE). The reason is as follows. The server is by design simple and will hopefully not have too much code. If someone wanted to reuse the project commercially and it was licensed under AGPL they might just look at the code and reimplement it in a closed-source way. This is less of a risk with a larger project. So, to avoid this and ensure the greatest chance of adoption it makes sense to license this project under MIT.
