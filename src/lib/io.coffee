# Raspberry Pi Fermentation temperature logging & control application
#
# (c) Joshua Farr <j.wgasa@gmail.com>
#
gpio 	= require 'rpi-gpio'

# class for controlling GPIO channels
class IO
	controlChannels_: []
	debug_: false
	direction_: 'out'

	constructor: (debug, direction) ->
		@debug_ = debug
		@direction_ = direction
		return

	# callback after gpio pin state change event completes
	# 
	# @param integer channel gpio pin that changed state
	# @param boolean value new pin state
	change: (channel, value) =>
		if @debug_
			console.log 'Channel ' + channel + ' value is now ' + value
		@controlChannels_[channel].locked = false
		@controlChannels_[channel].enabled = value
		return

	# query the status of a gpio pin
	#
	# @param integer channel gpio pin to be queried
	# @param function next callback with queried pin state
	status: (channel, next) =>
		if @direction_ isnt 'in'
			console.log 'IO must be set to "in" to query status!'
			return
		gpio.read channel, next
		return

	# callback after export event completes
	#
	# @param integer channel gpio pin that was exported
	export: (channel) =>
		if @debug_
			console.log 'Channel ' + channel + ' exported'
		@controlChannels_[channel].initialized = true
		return

	# enable access to gpio pins for each sensor with an active control mode
	setup: (config, next) =>
		gpio.on 'export', @export
		# use the gpio channel names and not the actual pin numbers to reference gpio channels
		gpio.setMode gpio.MODE_BCM
		for sensor in config.sensors
			if sensor.control != "none"
				if @debug_
					console.log 'Enabling GPIO ' + sensor.gpio + ' for writing...'
				direction = gpio.DIR_OUT
				if @direction_ is 'in'
					direction = gpio.DIR_IN
				gpio.setup sensor.gpio, direction, next
				@controlChannels_[sensor.gpio] = 
					enabled: false,
					locked: false,
					initialized: false
		# handler for change events
		gpio.on 'change', @change
		return

	# force internal state flag to a new state
	#
	# @param integer channel gpio pin to set
	# @param boolean state new state
	# @return previous state
	state: (channel, state) =>
		oldstate = @controlChannels_[channel].state
		@controlChannels_[channel].state = state
		oldstate

	# send a signal to a gpio pin
	#
	# @param integer channel gpio pin
	# @param boolean state new pin state
	# @param function external callback to be called after completion
	signal: (channel, state, next) ->
		if @enabled(channel) isnt state and not @locked(channel) and @initialized(channel)
			channels = @controlChannels_
			if @debug_
				console.log 'Writing to GPIO channel ' + channel
			gpio.write channel, state, next
			@controlChannels_[channel].locked = true
		return

	# query internal pin state
	# only looks at what we think it currently is - doesn't query the gpio
	#
	# @param integer channel gpio pin
	# @return boolean
	enabled: (channel) ->
		@controlChannels_[channel].enabled

	# query whether the pin is currently locked from making changes
	#
	# @param integer channel gpio pin
	# @return boolean
	locked: (channel) ->
		@controlChannels_[channel].locked

	# query whether then pin is initialized for use
	#
	# @param integer channel gpio pin
	# @return boolean
	initialized: (channel) ->
		@controlChannels_[channel].initialized

# export class
module.exports = IO
