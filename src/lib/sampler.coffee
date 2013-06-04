# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

# interface to temperature sensors
Thermometer	 = require './thermometer.js'
EventEmitter = require('events').EventEmitter

# The Sampler is used to continuously take temperature readings from temperature sensors.
class Sampler extends EventEmitter
	shutdown_: false
	frequency_: 1000
	sensors_ : {}
	thermo_: null
	sampling_: false
	debug_: false

	# Construct a new sampler instance
	#
	# @param integer frequency how often in ms to poll the sensors
	# @param array sensors array of sensors to be sampled
	# @param string units celsius or farenheight
	constructor: (frequency, sensors, units, debug) ->
		@sensors_ = sensors
		@frequency_ = frequency
		@debug_ = debug
		@thermo_ = new Thermometer units
		@on 'sample', @sample


	# Start sampling by scheduling the first sample
	# There will be a delay of @frequency_ before the first sample is taken.
	startSampling: () =>
		if @sampling_
			return
		if @debug_
			console.log 'Scheduling sensor sampling...'
		@scheduleSample()
		return


	emitSampleSignal: () => 
		@emit 'sample'
		return

	# Take a temperature sample from each sensor
	sample: () =>
		# for each configured sensor
		for sensor in @sensors_
			# poll sensor to get current temperature reading
			sensorReading = @thermo_.temperature sensor.id
			if @debug_
				console.log sensor.name + '[' + sensor.id + '] : ' + sensorReading

			@emit 'read', sensor.name, sensorReading

		# schedule next sample
		if not @shutdown_
			@scheduleSample()
		return


	scheduleSample: () =>
		setTimeout @emitSampleSignal, @frequency_
		@sampling_ = true
		return


module.exports = Sampler
