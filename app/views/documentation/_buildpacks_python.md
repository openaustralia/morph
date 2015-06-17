### Quick start

1. Install `virtualenv` and `pip` for package management, and `BeautifulSoup4` for HTML parsing:
<pre>sudo apt-get install python-pip python-bs4 python-dev python-virtualenv</pre>

2. Create a `virtualenv` and activate it.
<pre>
virtualenv --system-site-packages oaf
source oaf/bin/activate
</pre>

3. Fork and clone the scraper you're going to work on:
<pre>
git clone git@github.com:yourname/example.git
cd example
</pre>

4. Use `pip` to install the dependencies:
<pre>pip install -r requirements.txt</pre>

5. Run the scraper locally:
<pre>python scraper.py</pre>

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
