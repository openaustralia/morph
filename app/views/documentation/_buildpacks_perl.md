### Installing libraries from CPAN

To choose which libraries to install you will need a file `cpanfile` in the root of your scraper
directory. It can install anything from [CPAN](http://www.cpan.org/) and has a very straightforward syntax.

For instance to install specific versions of `HTTP::Message` and `XML::Parser` your `cpanfile` should
look like
<pre>
requires "HTTP::Message", "6.06";
requires "XML::Parser", "2.41";
</pre>

You don't have to specify the versions to install but it's recommended as otherwise different
runs of the scraper could potentially use different versions of libraries.

Check `cpanfile` into git alongside your scraper and the next time it's run on morph it will install
the libraries.
