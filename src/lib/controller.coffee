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
	profiles_: []

	# Default constructor
	#
	# @param array config sensor configuration array
	# @param bool debug verbose debugging output flag
	# @param bool nolog flag indicating whether to log to statsd or not
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
		query.exec @loadProfiles

		@io_ = new IO @debug_, 'out'

		@sockets_ = new Sockets @
		@sockets_.run()

		@sampler_ = new Sampler @config_.pollFrequency, @config_.sensors, @config_.sensorUnit, @debug_
		@sampler_.on 'read', @processSample

		ExpressApp.set 'controller', @
		if @debug_
			console.log 'Express API listening on port [' + @config_.apiPort + ']'
		ExpressApp.listen @config_.apiPort

		return

	# Process profiles loaded from the db
	#
	# @param err error message defined if there was an error loading profiles
	# @param array profiles collection of profile documents
	loadProfiles: (err, profiles) =>
		if err
			if @debug_
				console.log err
			return
		@profiles_ = profiles
		for profile in profiles
			@state_[profile.sensor].profile = profile
			@state_[profile.sensor].mode = profile.control_mode
			if profile.overrides.length > 0 and profile.overrides[profile.overrides.length - 1].action isnt 'resume'
				value = false
				if profile.overrides[profile.overrides.length - 1].action is 'on'
					value = true
				@setGpio profile.sensor, value
			if @debug_
				console.log 'Bound active profile [' + profile.name + '] to sensor [' + profile.sensor + ']'

	# Begin sampling sensor data
	run: () =>
		for sensor in @config_.sensors
			if sensor.gpio?
				@io_.setupChannel sensor.gpio, 'out'
		@sampler_.startSampling()

	# Get debug status flag setting
	#
	# @return bool debug setting
	debug: () =>
		@debug_

	# Get sensor configuration array
	#
	# @return array configuration array
	config: () =>
		@config_

	# Get GPIO state of the channel associated with a sensor
	#
	# @param string sensor name of sensor
	# @return bool GPIO state
	getGpio: (sensor) =>
		@state_[sensor].gpio

	# Set the GPIO state of the channel associated with a sensor
	#
	# @param string sensor name of the sensor
	# @param bool new GPIO state
	setGpio: (sensor, value) =>
		if @state_[sensor].gpio is value
			return
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

	# Set a new Set Value for a sensor
	#
	# @param string sensor name of the sensor
	# @param integer value new SV
	setSv: (sensor, value) =>
		@state_[sensor].sv = value
		data =
			sensor: sensor
			value: value
		@sockets_.io_.sockets.emit 'setsv', data
		return

	# Get the current Set Value for a sensor
	#
	# @return integer current SV
	getSv: (sensor) =>
		@state_[sensor].sv

	# Set the control mode of a sensor
	#
	# @param string sensor name of the sensor
	# @param string mode one of: auto, manual, pid, none
	setMode: (sensor, mode) =>
		@state_[sensor].mode = mode
		return

	# Get the current control mode of a sensor
	#
	# @param string sensor
	# @return string current mode setting
	getMode: (sensor) =>
		@state_[sensor].mode

	# update the current sensor state based on the active profile
	#
	# @param string sensor sensor name
	# @return boolean true if the profile is currently overridden
	checkSensorProfile: (sensor) =>
		override = false
		if @state_[sensor].profile is null
			return override

		# find the current step
		activeStep = null
		now = new Date()
		profileStart = @state_[sensor].profile.start_time
		modified = false
		# active profile started for the first time
		if profileStart is undefined
			profileStart = new Date()
			if @debug_
				console.log 'Enabling profile at [' + profileStart.toString() + ']'
			@state_[sensor].profile.start_time = profileStart
			history = 
				action: 'start_profile'
				state: 'on'
				time: profileStart
			@state_[sensor].profile.history.push history
			modified = true

		profileDuration = 0
		# find active step
		for step in @state_[sensor].profile.steps
			profileDuration += step.duration
			if step.completed is true
				continue
			stepEnd = new Date()
			stepEnd.setDate profileStart.getDate() + profileDuration
			if stepEnd > now
				activeStep = step
				if step.active is false
					step.active = true
					step.start_time = now
					modified = true
					console.log 'Enabling step [' + step.name + '] at [' + now.toString() + ']'
					history = 
						action: 'start_step'
						state: 'on'
						time: now
					@state_[sensor].profile.history.push history
				break
			else
				if step.active is true
					step.end_time = now
					step.active = false
				step.completed = true
				modified = true
				console.log 'Completed step [' + step.name + '] at [' + now.toString() + ']'
				history = 
					action: 'end_step'
					state: 'off'
					time: now
				@state_[sensor].profile.history.push history

		if modified is true
			@state_[sensor].profile.save()

		# check if there is an override currently in effect
		if @state_[sensor].profile.overrides.length > 0
			if @state_[sensor].profile.overrides[@state_[sensor].profile.overrides.length-1].action isnt 'resume'
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

	# Process a temperature reading sample from a sensor
	#
	# @param string sensor name of the sensor
	# @param integer value current sensor reading
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

		override = @checkSensorProfile sensor

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
