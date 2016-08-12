default: build run

build:
	docker build -t classroom .

rebuild:
	docker build --no-cache -t classroom .

run:
	docker run -i --name classroom --rm -v "$(PWD)":/srv/www -t classroom
