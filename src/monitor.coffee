# Raspberry Pi Fermentation temperature logging & control application
#
# (c) Joshua Farr <j.wgasa@gmail.com>
#

EventEmitter = require('events').EventEmitter
statsd 		 = require('node-statsd').StatsD
argv		 = require('optimist').argv

# local app configuration
config 		 = require './lib/config.js'
# interface to temperature sensors
Thermometer	 = require './lib/thermometer.js'
IO 			 = require './lib/io.js'

thermo = new Thermometer()
# temperature readings are in F or C?
thermo.unit config.sensorUnit

# --sensors CLI option prints out each of the detected ds18b20 serial #'s and exits
if argv.sensors
	console.log 'Querying sensor ids...'
	sensors = thermo.sensors()
	console.log sensor for sensor in sensors
	return


# --query <id> CLI option queries the temperature of the sensor, displays it and exits
if argv.query
	console.log 'Querying sensor id [' + argv.query + ']...'
	sensorReading = thermo.temperature argv.query
	console.log 'Temperature: ' + sensorReading
	return


# --control <channel> CLI option sends a control signal to the gpio channel
# must be used in conjunction with --enable or --disable
if argv.control
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

	return


# --status <channel> CLI option queries the status of the gpio channel, displays it, and exits
if argv.status
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
	return



io = new IO(argv.debug, 'out')


emitter = new EventEmitter()
statsdClient = new statsd()

shutdown = false


emitSampleSignal = () -> 
	emitter.emit 'sample'
	return

sample = () ->
	# for each configured sensor
	for sensor in config.sensors
		# poll sensor to get current temperature reading
		sensorReading = thermo.temperature sensor.id
		if argv.debug
			console.log sensor.name + '[' + sensor.id + '] : ' + sensorReading
		# log temperature
		if not argv.nolog
			statsdClient.gauge sensor.name, sensorReading

		continue if sensor.control is "none"
		# control channel is already locked from a pending update so skip trying to change it
		continue if io.locked(sensor.gpio) is true

		controlName = sensor.name + '_gpio_' + sensor.gpio
		if sensor.control is "manual"
			if sensorReading > sensor.sv and io.enabled sensor.gpio
				if argv.debug
					console.log 'disabling io channel: ' + sensor.gpio
				io.signal sensor.gpio, false
				statsdClient.decrement controlName
			else if sensorReading < sensor.sv and not io.enabled sensor.gpio
				if argv.debug
					console.log 'enabling io channel: ' + sensor.gpio
				io.signal sensor.gpio, true
				statsdClient.increment controlName
	#	if pid attached to sensor
	#		set current pv in pid
	#		do pid computation
	#		use pid output to drive gpio signal

	# schedule next sample
	if not shutdown
		setTimeout emitSampleSignal, config.pollFrequency
	return

emitter.on 'sample', sample


startSampling = () ->
	setTimeout emitSampleSignal, config.pollFrequency
	return

io.setup(config, startSampling)

