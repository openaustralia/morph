upstream faye_backend {
  server 127.0.0.1:9292;
}

server {
  listen 443;
  server_name faye.{{ server_name }};
  access_log /var/log/nginx/faye.access.log;
  error_log /var/log/nginx/faye.error.log;

  ssl on;
  ssl_certificate /etc/letsencrypt/live/{{ server_name }}/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/{{ server_name }}/privkey.pem; # managed by Certbot

  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_session_cache  builtin:1000  shared:SSL:10m;
  ssl_ciphers 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4';
  ssl_dhparam dhparam.pem;

  location / {
    proxy_pass http://faye_backend;
    #proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
