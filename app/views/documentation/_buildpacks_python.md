### Install libraries

For Python morph.io installs libraries using `pip` from a `requirements.txt` file in the root of
your scraper repository. The format for `requirements.txt` is straightforward.

For example to install specific version of the `Pygments` and `SQLAlchemy` library, `requirements.txt`
could look like this
<pre>
Pygments==1.4
SQLAlchemy==0.6.6
</pre>

### Setting Python version

You can also specify the Python version to run by adding a `runtime.txt` file.

For example, for Python 2.7.6 put this in `runtime.txt`
<pre>
python-2.7.6
</pre>

### Default libraries and Python version

If you don't specify a `requirements.txt` or `runtime.txt` file, morph will insert defaults
for you which are designed to be as close as possible to the environment provided by ScraperWiki
Classic as it was in January 2014.
