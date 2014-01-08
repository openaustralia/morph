<VirtualHost *:80>
    ServerName morph.io
    DocumentRoot "/var/www/current/public"

    RailsEnv vagrant
    PassengerRuby /home/deploy/.rvm/rubies/ruby-2.0.0-p353/bin/ruby

    <Directory "/var/www/current/public">
        Order allow,deny
        Allow from all
        Options -MultiViews

        AuthType Basic
        AuthName "Morph says an odd hello"
        AuthUserFile /var/www/shared/htpasswd
        Require user test
    </Directory>

    # TODO Create /var/www/shared/log directory. For the time being keep these commented out
    #ErrorLog "/var/www/shared/log/error_log"
    #CustomLog /var/www/shared/log/access_log common
</VirtualHost>