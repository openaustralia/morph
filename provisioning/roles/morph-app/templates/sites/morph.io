server {
  listen 443;
  server_name {{ server_name }} api.{{ server_name }};
  root /var/www/current/public;
  passenger_enabled on;
  passenger_ruby /home/deploy/.rvm/gems/ruby-2.3.1/wrappers/ruby;

  ssl on;
  ssl_certificate /etc/sslmate/morph.io.chained.crt;
  ssl_certificate_key /etc/sslmate/morph.io.key;

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_ciphers 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4';
  ssl_dhparam dhparam.pem;
}
