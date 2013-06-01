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
				@state_[profile.sensor].profile = profile
				@state_[profile.sensor].mode = profile.control_mode
				if @debug_
					console.log 'Bound active profile [' + profile.name + '] to sensor [' + profile.sensor + ']'
		query.exec profileCallback

		@io_ = new IO @debug_, 'out'
		@sockets_ = new Sockets @
		@sockets_.run()
		@sampler_ = new Sampler @config_.pollFrequency, @config_.sensors, @config_.sensorUnit, @

		ExpressApp.set 'controller', @
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

	# update the current sensor state based on the active profile
	# @return boolean true if the profile is currently overridden
	checkSensorProfile: () =>
		override = false
		if @state_[sensor].profile is null
			override

		# find the current step
		activeStep = null
		now = new Date()
		profileStart = @state_[sensor].profile.start_time
		if profileStart is undefined
			profileStart = new Date()
			if @debug_
				console.log 'Enabling profile at [' + profileStart.toString() + ']'
			@state_[sensor].profile.start_time = profileStart
			@state_[sensor].profile.save()
		for step in @state_[sensor].profile.steps
			stepEnd = new Date()
			stepEnd.setDate profileStart.getDate() + step.duration
			if stepEnd > now
				activeStep = step
				break

		# check if there is an override currently in effect
		if @state_[sensor].profile.overrides.length > 0
			if @state_[sensor].overrides[@state_[sensor].profile.overrides.length].action isnt 'resume'
				override = true

		# has the mode changed?
		if @state_[sensor].profile.control_mode isnt @state_[sensor].mode
			if @debug_
				console.log 'Switching sensor [' + sensor + '] control mode from [' + @state_[sensor].mode + '] to [' + @state_[sensor].profile.control_mode + ']'
			@state_[sensor].mode = @state_[sensor].profile.control_mode

		# has the SV changed?
		if activeStep isnt null and @state_[sensor].sv isnt activeStep.temperature
			if @debug_
				console.log 'Setting sensor [' + sensor + '] SV to Profile [' + @state_[sensor].profile.name + '] Step [' + activeStep.name + '] temperature [' + activeStep.temperature + ']'
			@state_[sensor].sv = activeStep.temperature

		override


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

		override = @checkSensorProfile()

		if @state_[sensor].mode is 'auto' and override isnt true
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
