all: build

build:
	docker build -t openaustralia/morph-mitmdump .

run: build
	docker run -i -t -p 8080:8080 openaustralia/morph-mitmdump
