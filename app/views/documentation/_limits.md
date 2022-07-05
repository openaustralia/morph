Right now there are very few limits. We are trusting you that you won't abuse
this.

However, we do impose a couple of hard limits on running scrapers so they don't
take up too many resources

* max <%= number_to_human_size Morph::DockerRunner.default_memory_limit %> memory
* max 24 hours run time for a single run

If a scraper runs out of memory or runs too long it will get killed
automatically.

If you're hitting up against these hard limits and still want to use morph.io
please [do get in touch](mailto:contact@oaf.org.au) and let us know and we'll
see what we can do to help.

There's also a soft limit:

* max <%= number_with_delimiter Morph::Runner.default_max_lines %> lines of log output

If a scraper generates more than <%= number_with_delimiter Morph::Runner.default_max_lines %> lines
of log output the scraper will continue running uninterrupted. You just won't
see any more output than that. To avoid this happening simply print less stuff
to the screen.

Note that we are keeping track of the amount of cpu time (and a whole bunch of
other metrics) that you and your scrapers are using. So, if we do find that you
are using too much (and no we don't know what that is right now) we reserve the
right to kick you out. In reality first we'll ask you nicely to stop.
