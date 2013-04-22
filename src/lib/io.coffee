gpio 	= require 'rpi-gpio'

class IO
	controlChannels_: []
	debug_: false

	constructor: (debug) ->
		@debug_ = debug
		return

	change: (channel, value) =>
		if @debug_
			console.log 'Channel ' + channel + ' value is now ' + value
		@controlChannels_[channel].locked = false
		@controlChannels_[channel].enabled = value
		return

	export: (channel) =>
		if @debug_
			console.log 'Channel ' + channel + ' exported'
			@controlChannels_[channel].initialized = true

	# enable access to gpio pins for each sensor with an active control mode
	setup: (config, next) =>
		gpio.on 'export', @export
		# use the gpio channel names and not the actual pin numbers to reference gpio channels
		gpio.setMode gpio.MODE_BCM
		for sensor in config.sensors
			if sensor.control != "none"
				if @debug_
					console.log 'Enabling GPIO ' + sensor.gpio + ' for writing...'
				gpio.setup sensor.gpio, gpio.DIR_OUT, next
				@controlChannels_[sensor.gpio] = 
					enabled: false,
					locked: false,
					initialized: false
		# handler for change events
		gpio.on 'change', @change
		return

	signalCallback: (err) ->
		if err
			throw err
		return

	signal: (channel, state, next) ->
		if @enabled(channel) isnt state and not @locked(channel) and @initialized(channel)
			channels = @controlChannels_
			if @debug_
				console.log 'Writing to GPIO channel ' + channel
			gpio.write channel, state, next
			@controlChannels_[channel].locked = true
		return

	enabled: (channel) ->
		@controlChannels_[channel].enabled

	locked: (channel) ->
		@controlChannels_[channel].locked

	initialized: (channel) ->
		@controlChannels_[channel].initialized

module.exports = IO
