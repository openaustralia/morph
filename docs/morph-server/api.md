# A straw-man for the morph server API

## Overview of data that gets passed back and forth when scraper is run

For the purposes of this we're only going to consider a scraper that runs successfully (and completes) without any errors. This is useful to get an overall understanding of the big picture,
of how the overall data flow works.

Passes:
* Directory with code of scraper, configuration and data to run
* A set of environment variables to set for the scraper run
* List of files we want back at the end of the scraper run

Returns:
* A real-time stream of console log output
* A real-time stream of other helpful output (like compiler messages)
* A real-time stream of web pages being hit during compile stage
* A real-time stream of web pages being hit during scraper run
* Metrics of cpu, memory and network usage during compile stage (if any)
* Metrics of cpu, memory and network usage during scraper run
* Exit code of scraper script
* The contents of a particular set of files

The real-time data could all be merged together in one stream by putting it together
into something like an "event log". All real-time things are "events" and they're
all multiplexed into the same stream. Then we can give each event an id (a count)
which can also be used to reconnect to the event stream and start from the last
recorded event.

## Start a scraper run

Actually start a scraper. Give it the scraper code (in any language supported by buildstep)
and any associated data it needs locally. This will return as soon as the scraper
is compiling and/or running with the "run ID" which uniquelly identifies this scraper run.
You will need this run ID to subsequently track and access this scraper.

Passes:
* Directory with code, configuration and data to run
* A set of environment variables to set for the scraper run (optionally)

Returns:
* Run ID

## Attach to scraper event stream

Watch what is happening to a scraper in real-time as it gets compiled and runs.
By default this will stream all events that have occurred from the scraper
getting started until now and then as new events occur stream those in real-time.
If for any reason this connection dies (or you stop it), you can reconnect with
the last successfully received event ID and the stream will start from the next
event.

Note that even if a scraper has completed or failed calling this should succeed.
As in it should be possible to get the whole event log of everything that happened
even if nothing is currently running.

Passes:
* Run ID
* Event ID to start from (optionally)

Returns:
* A stream of event objects as [line delimited JSON](https://en.wikipedia.org/wiki/JSON_Streaming). Events can be:
  * console log output
  * compiler / build messages
  * web pages being hit during compile stage
  * web pages being hit during scraper run
  * Events signalling different stages (queued, compiling, running, exited with particular exit code)

## Stop scraper run

Use this when you want to stop a running scraper cleanly

Passes:
* Run ID

Returns:
* Whether the run was successfully stopped or not

## Get metrics

Usually at the end of a scraper run you want to know stuff about how much resources
it took.

TODO: What to do if the scraper run hasn't actually finished?

Passes:
* Run ID

Returns:
* Metrics of cpu, memory and network usage during compile stage (if any)
* Metrics of cpu, memory and network usage during scraper run

## Get files

Usually at the end of the scraper run you want to grab the contents of a file
which is probably the result of scraping. This allows you to do that.

TODO: What to do if the scraper run hasn't actually finished?

Passes:
* Run ID
* The path to the files to grab

Returns:
* The contents of the particular files

## Finalise scraper run

If a scraper isn't stopped or finished after a certain amount of time it should be automatically cleaned up. This is to ensure that the morph server is only stateful over the short term.

TODO: What to do if the scraper run hasn't actually finished?

Passes:
* Run ID

Returns:
* Whether this was successful or not
