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

# --query <id> CLI option queries the temperature of the sensor, displays it and exists
if argv.query
	console.log 'Querying sensor id [' + argv.query ']...'
	sensorReading = thermo.temperature argv.query
	console.log 'Temperature: ' + sensorReading
	return

io = new IO(argv.debug)
io.setup(config)

emitter = new EventEmitter()
statsdClient = new statsd()

shutdown = false


emitSampleSignal = -> 
	emitter.emit 'sample'
	return

sample = ->
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
		continue if IO.locked(sensor.gpio) is true

		controlName = sensor.name + '_gpio_' + sensor.gpio
		if sensor.control is "manual"
			if sensorReading > sensor.sv and IO.enabled sensor.gpio
				if argv.debug
					console.log 'disabling io channel: ' + sensor.gpio
				IO.signal sensor.gpio, false
				statsdClient.decrement controlName
			else if sensorReading < sensor.sv and not IO.enabled sensor.gpio
				if argv.debug
					console.log 'enabling io channel: ' + sensor.gpio
				IO.signal sensor.gpio, true
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

setTimeout emitSampleSignal, config.pollFrequency


