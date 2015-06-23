all: build

build:
	docker build -t openaustralia/morph-mitmdump .

run: build
	docker run -e "MORPH_URL=http://10.0.0.101:3000" -e "MITMPROXY_SECRET=abc123" -p 8080:8080 openaustralia/morph-mitmdump
