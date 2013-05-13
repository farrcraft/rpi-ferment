COFFEE_PATH="`pwd`/node_modules/coffee-script/bin/coffee"

all: build

build:
	$(COFFEE_PATH) --compile --output lib/ src/lib/
	$(COFFEE_PATH) --compile --output . src/monitor.coffee

modules:
	npm install
	npm install https://github.com/sigsegv42/rpi-pid/tarball/master
	#npm install statsd@0.6.0
	sudo npm install -g forever@0.10.0

clean:
	rm -rf lib

.PHONY: build modules clean
