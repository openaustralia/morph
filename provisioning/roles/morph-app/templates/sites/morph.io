server {
  listen 443;
  server_name {{ server_name }} api.{{ server_name }};
  root /var/www/current/public;
  passenger_enabled on;
  passenger_ruby /home/deploy/.rvm/gems/ruby-{{ ruby_version }}/wrappers/ruby;
  passenger_max_request_queue_size 300;

  # There's a lot of traffic coming to this one scraper. It was putting
  # too much load on the server. So, block it completely.
  location /CookieMichal/us-proxy {
    deny all;
  }

  ssl on;
  ssl_certificate /etc/letsencrypt/live/{{ server_name }}/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/{{ server_name }}/privkey.pem; # managed by Certbot

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_ciphers 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4';
  ssl_dhparam dhparam.pem;
}
