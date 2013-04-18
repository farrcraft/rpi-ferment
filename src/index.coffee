EventEmitter = require('events').EventEmitter
statsd 		 = require('node-statsd').StatsD
argv		 = require('optimist').argv

# local app configuration
config 		 = require './lib/config.js'
Thermometer	 = require './lib/thermometer.js'

thermo = new Thermometer()

if argv.sensors
	sensors = thermo.sensors()
	console.log sensor for sensor in sensors
	return


emitter = new EventEmitter()

shutdown = false

statsdClient = new statsd();

emitSampleSignal = -> 
	emitter.emit 'sample'
	return

sample = ->
	console.log 'sampling...'
	# for each configured sensor:
	#	poll sensor to get current temperature reading
	#	log temperature
	statsdClient.gauge sensorName, sensorReading
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


