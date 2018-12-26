all: build

build:
	docker build -t openaustralia/morph-mitmdump .
	docker container rm mitmdump2 && docker container create --network host -e "MORPH_URL=http://10.0.0.101:3000" -e "MITMPROXY_SECRET=abc123" -p 8080:8080 --name mitmdump2 openaustralia/morph-mitmdump

start: build
	docker container start mitmdump2

stop: build
	docker container stop mitmdump2

run: build
	docker run -e "MORPH_URL=http://10.0.0.101:3000" -e "MITMPROXY_SECRET=abc123" -p 8080:8080 openaustralia/morph-mitmdump
