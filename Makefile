COFFEE_PATH="`pwd`/node_modules/coffee-script/bin/coffee"

all: build

build:
	$(COFFEE_PATH) --compile --output lib/ src/lib/
	$(COFFEE_PATH) --compile --output . src/index.coffee

modules:
	npm install coffee-script
	npm install https://github.com/sigsegv42/rpi-pid/tarball/master
	npm install statsd@0.6.0
	npm install node-statsd@0.0.7
	npm install optimist@0.4.0
	sudo npm install -g forever@0.10.0
	npm install rpi-gpio@0.0.4

clean:
	rm -rf lib

.PHONY: build modules clean
