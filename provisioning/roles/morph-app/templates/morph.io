{% if ssl %}
<VirtualHost *:80>
    ServerName {{ server_name }}
    ServerAlias api.{{ server_name }}
    RedirectMatch permanent ^/(.*) https://{{ server_name }}/$1
</VirtualHost>
{% endif %}

{% if ssl %}
<VirtualHost *:443>
{% else %}
<VirtualHost *:80>
{% endif %}

    ServerName {{ server_name }}
    ServerAlias api.{{ server_name }}
    DocumentRoot "/var/www/current/public"

    PassengerRuby /home/deploy/.rvm/gems/ruby-2.0.0-p353/wrappers/ruby

    #ErrorLog "/srv/www/www.openaustraliafoundation.org.au/log/error_log"
    #CustomLog /srv/www/www.openaustraliafoundation.org.au/log/access_log common

    <Location "/">
        Order allow,deny
        Allow from all
        Options -MultiViews
    </Location>

    # A regex for the API url. Let's open this up to the world
    <LocationMatch "/[^/]+/[^/]+/data>
        # All access controls and authentication are disabled
        Satisfy Any
        Allow from all
    </LocationMatch>

    <Location "/run>
        # All access controls and authentication are disabled
        Satisfy Any
        Allow from all
    </Location>

{% if ssl %}
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
{% endif %}

</VirtualHost>


