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

<VirtualHost *:443>
    ServerName {{ server_name }}
    ServerAlias api.morph.io
    DocumentRoot "/var/www/current/public"

    #ErrorLog "/srv/www/www.openaustraliafoundation.org.au/log/error_log"
    #CustomLog /srv/www/www.openaustraliafoundation.org.au/log/access_log common

    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM

    SSLCertificateFile /etc/apache2/ssl/ssl.crt
    SSLCertificateKeyFile /etc/apache2/ssl/ssl.key
    SSLCertificateChainFile /etc/apache2/ssl/sub.class1.server.ca.pem
    SSLCACertificateFile /etc/apache2/ssl/ca.pem

    #CustomLog /srv/www/www.openaustraliafoundation.org.au/log/ssl_request_log \
    #  "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
</VirtualHost>
