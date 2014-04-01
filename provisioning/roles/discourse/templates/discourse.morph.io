upstream discourse_backend {
  server 127.0.0.1:8000;
}

# TODO: Make it SSL
server {
  listen 80;
  server_name discourse.{{ server_name }};

  location / {
    proxy_pass http://discourse_backend;
  }
}
