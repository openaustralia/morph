<VirtualHost *:80>
    ServerName {{ server_name }}
    ServerAlias api.morph.io
    DocumentRoot "/var/www/current/public"

    PassengerRuby /home/deploy/.rvm/rubies/ruby-2.0.0-p353/bin/ruby

    <Location "/">
        Order allow,deny
        Allow from all
        Options -MultiViews

        AuthType Basic
        AuthName "Morph says an odd hello"
        AuthUserFile /var/www/shared/htpasswd
        Require user test
    </Location>

    # A regex for the API url. Let's open this up to the world
    <LocationMatch "/[^/]+/[^/]+/data>
        # All access controls and authentication are disabled
        Satisfy Any
        Allow from all
    </LocationMatch>

    # TODO Create /var/www/shared/log directory. For the time being keep these commented out
    #ErrorLog "/var/www/shared/log/error_log"
    #CustomLog /var/www/shared/log/access_log common
</VirtualHost>