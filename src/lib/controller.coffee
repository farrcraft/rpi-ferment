# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

statsd 		= require('node-statsd').StatsD
Sampler		= require './sampler.js'
IO 			= require './io.js'
Sockets		= require './sockets.js'
ExpressApp 	= require './server.js'
mongoose 	= require 'mongoose'

require './orm/profile.js'


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
			if @debug_
				console.log 'Creating statsd client...'
			@statsd_ = new statsd()
		for sensor in config.sensors
			@state_[sensor.name] =
				sv: 0
				pv: 0
				gpio: false
				mode: 'manual'
				profile: null
			if sensor.type isnt 'ambient'
				@state_[sensor.name].channel = sensor.gpio

		# load active profiles
		model = mongoose.model 'Profile'
		query = model.find()
		query.where 'active', true
		profileCallback = (err, profiles) =>
			if err
				return
			for profile in profiles
				@state_[profile.sensor] = profile
				if @debug_
					console.log 'Bound active profile [' + profile.name + '] to sensor [' + profile.sensor + ']'
		query.exec profileCallback

		@io_ = new IO @debug_, 'out'
		@sockets_ = new Sockets @
		@sockets_.run()
		@sampler_ = new Sampler @config_.pollFrequency, @config_.sensors, @config_.sensorUnit, @
		if @debug_
			console.log 'Express API listening on port [' + @config_.apiPort + ']'
		ExpressApp.listen @config_.apiPort
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
		controlSignalCompletion = =>
			if @debug_
				console.log 'GPIO channel state updated'
				data =
					sensor: sensor
					state: value
				@sockets_.io_.sockets.emit 'setgpio', data
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
		data =
			sensor: sensor
			value: value
		@sockets_.io_.sockets.emit 'setsv', data
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

		if @debug_
			console.log 'Processing sample value [' + value + '] for sensor [' + sensor + ']' 

		statsdCallback = () =>
			if @debug_
				console.log 'statsd gauge data sent.'

		if @statsd_
			@statsd_.gauge sensor, value, 1, statsdCallback

		if not @state_[sensor].gpio?
			return

		if @state_[sensor].mode is 'auto'
			if value > @state_[sensor].sv and @state_[sensor].gpio
				if @debug_
					console.log 'Disabling gpio channel: ' + @state_[sensor].channel
				@setGpio sensor, false
			else if value < @state_[sensor].sv and not @state_[sensor].gpio
				if @debug_
					console.log 'Enabling gpio channel: ' + @state_[sensor].channel
				@setGpio sensor, true
		#	if pid attached to sensor
		#		set current pv in pid
		#		do pid computation
		#		use pid output to drive gpio signal

		return

module.exports = Controller
