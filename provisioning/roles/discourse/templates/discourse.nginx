# TODO: Make it SSL
server {
  listen 80;
  server_name {{ discourse_server_name }};

  location / {
    proxy_pass http://localhost:8000;
  }
}
