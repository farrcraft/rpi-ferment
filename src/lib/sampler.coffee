# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

# interface to temperature sensors
Thermometer	 = require './thermometer.js'
EventEmitter = require('events').EventEmitter


class Sampler extends EventEmitter
	shutdown_: false
	controller_: null
	frequency_: 1000
	sensors_ : {}
	thermo_: null
	sampling_: false

	constructor: (frequency, sensors, units, controller) ->
		@sensors_ = sensors
		@frequency_ = frequency
		@controller_ = controller
		@thermo_ = new Thermometer units
		@on 'sample', @sample


	startSampling: () =>
		if @sampling_
			return
		if @controller_.debug()
			console.log 'Scheduling sensor sampling...'
		@scheduleSample()
		return


	emitSampleSignal: () => 
		@emit 'sample'
		return


	sample: () =>
		# for each configured sensor
		for sensor in @sensors_
			# poll sensor to get current temperature reading
			sensorReading = @thermo_.temperature sensor.id
			if @controller_.debug()
				console.log sensor.name + '[' + sensor.id + '] : ' + sensorReading

			@controller_.processSample sensor.name, sensorReading

		# schedule next sample
		if not @shutdown_
			@scheduleSample()
		return


	scheduleSample: () =>
		setTimeout @emitSampleSignal, @frequency_
		@sampling_ = true
		return


module.exports = Sampler