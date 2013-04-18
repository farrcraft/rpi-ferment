EventEmitter = require('events').EventEmitter
statsd 		 = require('node-statsd').StatsD
argv		 = require('optimist').argv

# local app configuration
config 		 = require './lib/config.js'
Thermometer	 = require './lib/thermometer.js'

thermo = new Thermometer()
thermo.unit 'farenheight'

# --sensors CLI option prints out each of the detected ds18b20 serial #'s and exits
if argv.sensors
	console.log 'Querying sensor ids...'
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
	# for each configured sensor (config.sensors)
	for sensor in config.sensors
		# poll sensor to get current temperature reading
		sensorReading = thermo.temperature sensor.id
		if argv.debug
			console.log sensorReading
		# log temperature
		if not argv.nolog
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


