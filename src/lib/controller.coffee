# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

statsd 		= require('node-statsd').StatsD
Sampler		= require './sampler.js'
IO 			= require './io.js'
Sockets		= require './sockets.js'

class Controller
	config_: {}
	state_: {}
	io_: null
	debug_: false
	statsd_: null
	sampler_: null
	sockets_: null

	constructor: (config, debug, nolog) ->
		@debug_ = debug
		@config_ = config
		if not nolog
			statsd_ = new statsd()
		for sensor in config.sensors
			@state_[sensor.name] =
				sv: 0
				pv: 0
				gpio: false
				mode: 'manual'
			if sensor.type isnt 'ambient'
				@state_[sensor.name].channel = sensor.gpio
		@io_ = new IO @debug_, 'out'
		@sockets_ = new Sockets @
		@sampler_ = new Sampler @config_.pollFrequency, @config_.sensors, @config_.sensorUnit, @
		return

	run: () =>
		@io_.setup @config_, @sampler_.startSampling

	debug: () =>
		@debug_

	config: () =>
		@config_

	getGpio: (sensor) =>
		@state_[sensor].gpio

	setGpio: (sensor, value) =>
		@state_[sensor].gpio = value
		controlSignalCompletion = ->
			if @debug_
				console.log 'GPIO channel state updated'
			return
		controlName = sensor + '_gpio_' + @state_[sensor].channel
		@io_.signal @state_[sensor].channel, value, controlSignalCompletion
		if not @statsd_
			return
		if not value
			@statsd_.decrement controlName
		else
			@statsd_.increment controlName
		return

	setSv: (sensor, value) =>
		@state_[sensor].sv = value
		return

	getSv: (sensor) =>
		@state_[sensor].sv

	setMode: (sensor, mode) =>
		@state_[sensor].mode = mode
		return

	getMode: (sensor) =>
		@state_[sensor].mode

	processSample: (sensor, value) =>
		@state_[sensor].pv = value

		if @statsd_
			@statsd_.gauge sensor, value

		if @config_[sensor].type isnt 'fermenter'
			return
		if @state_[sensor].mode is 'manual'
			if value > @state_[sensor].sv and @state_[sensor].gpio
				if @debug_
					console.log 'Disabling gpio channel: ' + @state_[sensor].gpio
				@setGpio sensor, false
			else if value < @state_[sensor].sv and not @state_[sensor].gpio
				if @debug_
					console.log 'Enabling gpio channel: ' + @state_[sensor].gpio
				@setGpio sensor, true
		#	if pid attached to sensor
		#		set current pv in pid
		#		do pid computation
		#		use pid output to drive gpio signal

		return

module.exports = Controller
