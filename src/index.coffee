# Raspberry Pi Fermentation temperature logging & control application
#
# (c) Joshua Farr <j.wgasa@gmail.com>
#

EventEmitter = require('events').EventEmitter
statsd 		 = require('node-statsd').StatsD
argv		 = require('optimist').argv
gpio		 = require 'rpi-gpio'

# local app configuration
config 		 = require './lib/config.js'
# interface to temperature sensors
Thermometer	 = require './lib/thermometer.js'

thermo = new Thermometer()
# temperature readings are in F or C?
thermo.unit config.sensorUnit

# --sensors CLI option prints out each of the detected ds18b20 serial #'s and exits
if argv.sensors
	console.log 'Querying sensor ids...'
	sensors = thermo.sensors()
	console.log sensor for sensor in sensors
	return

controlChannels = []

ioChange = (channel, value) ->
	console.log 'Channel ' + channel + ' value is now ' + value
	controlChannels[channel].locked = false
	controlChannels[channel].enabled = value

# enable access to gpio pins for each sensor with an active control mode
setupIO = ->
	for sensor in config.sensors
		if sensor.control is not "none"
			gpio.setup sensor.gpio gpio.DIR_OUT
			controlChannels[sensor.gpio] = 
				enabled: false,
				locked: false
	# handler for change events
	gpio.on 'change', ioChange


emitter = new EventEmitter()

shutdown = false

statsdClient = new statsd()

setupIO()

ioCallback = (err) ->
	if err
		throw err


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
		continue if controlChannels[sensor.gpio].locked is true

		controlName = sensor.name + '_gpio_' + sensor.gpio
		if sensor.control is "manual"
			if sensorReading > sensor.sv and controlChannels[sensor.gpio].enabled is true
				gpio.write sensor.gpio, false, ioCallback
				controlChannels[sensor.gpio].locked = true
				statsdClient.decrement controlName
			else if sensorReading < sensor.sv and controlChannels[sensor.gpio].enabled is not true
				gpio.write sensor.gpio, true, ioCallback
				controlChannels[sensor.gpio].locked = true
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


