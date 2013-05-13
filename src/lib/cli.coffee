# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

# local app configuration
config 		 = require './lib/config.js'
# interface to temperature sensors
Thermometer	 = require './lib/thermometer.js'
IO 			 = require './lib/io.js'

thermo = new Thermometer()
# temperature readings are in F or C?
thermo.unit config.sensorUnit

class Cli

	run: (argv) =>
		if argv.sensors
			return @sensors()
		else if argv.query
			return @query()
		else if argv.control
			return @control()
		else if argv.status
			return @status()
		false

	# --sensors CLI option prints out each of the detected ds18b20 serial #'s and exits
	sensors: () =>
		console.log 'Querying sensor ids...'
		sensors = thermo.sensors()
		console.log sensor for sensor in sensors
		true


	# --query <id> CLI option queries the temperature of the sensor, displays it and exits
	query: () =>
		console.log 'Querying sensor id [' + argv.query + ']...'
		sensorReading = thermo.temperature argv.query
		console.log 'Temperature: ' + sensorReading
		true


	# --control <channel> CLI option sends a control signal to the gpio channel
	# must be used in conjunction with --enable or --disable
	control: () =>
		if argv.enable
			mode = 'enable'
			state = true
		else if argv.disable
			mode = 'disable'
			state = false
		else
			console.log '--control <channel> requires either --enable or --disable option'
		console.log 'Sending ' + mode + ' signal to control channel ' + argv.control 

		end = () ->
			process.exit()
		send = () -> 
			# force internal io state to appear enabled if we're trying to send a disabled command
			if not state
				io.state true
			io.signal argv.control, state, end

		io = new IO(argv.debug, 'out')
		io.setup(config, send)
		true


	# --status <channel> CLI option queries the status of the gpio channel, displays it, and exits
	status: () =>
		console.log 'Querying status of GPIO channel ' + argv.status + '...'
		status = (err, value) ->
			state = 'off'
			if value
				state = 'on'
			console.log 'GPIO channel is ' + state
			process.exit()
			return
		query = () ->
			io.status argv.status, status
		io = new IO(argv.debug, 'in')
		io.setup(config, query)
		true

module.exports = Cli
