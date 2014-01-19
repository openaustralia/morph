<VirtualHost *:80>
    ServerName {{ server_name }}
    ServerAlias api.morph.io
    RedirectMatch permanent ^/(.*) https://morph.io/$1
</VirtualHost>

<VirtualHost *:443>
    ServerName {{ server_name }}
    ServerAlias api.morph.io
    DocumentRoot "/var/www/current/public"

    PassengerRuby /home/deploy/.rvm/rubies/ruby-2.0.0-p353/bin/ruby

    #ErrorLog "/srv/www/www.openaustraliafoundation.org.au/log/error_log"
    #CustomLog /srv/www/www.openaustraliafoundation.org.au/log/access_log common

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

    SSLEngine on

    SSLProtocol all -SSLv2 -SSLv3
    SSLHonorCipherOrder on
    SSLCipherSuite "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 \
    EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 \
    EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS"

    SSLCertificateFile /etc/apache2/ssl/ssl.crt
    SSLCertificateKeyFile /etc/apache2/ssl/ssl.key
    SSLCertificateChainFile /etc/apache2/ssl/sub.class1.server.ca.pem
    SSLCACertificateFile /etc/apache2/ssl/ca.pem

    #CustomLog /srv/www/www.openaustraliafoundation.org.au/log/ssl_request_log \
    #  "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
</VirtualHost>
