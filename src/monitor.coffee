# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

argv		 = require('optimist').argv

Cli 		 = require './lib/cli.js'
Controller 	 = require './lib/controller.js'
config  	 = require './lib/config.js'

# handle any cli options
cli = new Cli()
if cli.run argv
	return

controller = new Controller config, argv.debug, argv.nolog
controller.run()



