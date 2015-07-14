### Composer
PHP in morph.io uses [Composer](https://getcomposer.org/) for managing dependencies and runtime. You create
a file `composer.json` in the root of your scraper repository which defines what libraries and
extensions you want installed as well as the particular version of PHP that you want.

Depending on whether you have [Composer](https://getcomposer.org) locally or globally installed
on your personal machine you can run either
<pre>
php composer.phar install
</pre>

or
<pre>
composer install
</pre>

As well as installing the libraries locally it will also create a `composer.lock` file which should
be added alongside the `composer.json` file into git.

The next time the scraper runs on morph it will build an environment from this.

### Installing libraries

Your `composer.json` file can be used to say which extensions or libraries you want.

For instance, to install the `XSL` PHP extension your `composer.json` could look like this
<%= render 'documentation/libraries/php_example1.html.haml' %>

For more on the specifics of what can go in `composer.json` see the
[Composer documentation](https://getcomposer.org/doc/01-basic-usage.md).

### Setting PHP version
To set the version of PHP you want to use and to install PHP extensions and libraries
create `composer.json` in your scraper repository.

For instance, to use PHP 5.5.12 your `composer.json` could look like this

<%= render 'documentation/libraries/php_example2.html.haml' %>

There are currently a limited number of PHP versions that are supported. See the [list at Heroku PHP support](https://devcenter.heroku.com/articles/php-support#supported-versions).
