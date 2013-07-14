# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

http 		 = require 'http'
socketio	 = require 'socket.io'
auth 		 = require './services/auth.js'
db 			 = require './services/db.js'

class Sockets
	controller_: null
	io_: null

	constructor: (controller) ->
		@controller_ = controller

	httpHandler: (req, res) ->
		res.writeHead 200
		res.end ''
		return

	checkPermission: (access_token, callback) ->
		authCallback = (authed) ->
			#db.disconnect()
			if authed is true
				callback()
		#db.establishConnection()
		auth.checkAuthToken access_token, callback
		return

	run: () =>
		config = @controller_.config()
		if @controller_.debug()
			console.log 'Listening for socket connections on port [' + config.ioPort + '] ...'
		app = http.createServer @httpHandler
		@io_ = socketio.listen app
		app.listen config.ioPort
		@io_.sockets.on 'connection', @connectionHandler
		return

	connectionHandler: (socket) =>
		# send config to socket
		socket.on 'config', () =>
			if @controller_.debug()
				console.log 'Socket requested config'
			socket.emit 'config', @controller_.config()
			return

		# get gpio state for channel
		socket.on 'getgpio', (channel) =>
			state = @controller_.getGpio(channel)
			data =
				channel: channel
				state: state
			socket.emit 'gpio', data
			return

		# set gpio state for channel
		socket.on 'setgpio', (channel, state, access_token) =>
			setGpioCallback = () ->
				if @controller_.debug()
					console.log 'Socket requested GPIO channel [' + channel + '] set to state [' + state + ']'
				@controller_.setGpio channel, state
			@checkPermission access_token, setGpioCallback
			return

		# set sensor sv
		socket.on 'setsv', (sensor, sv, access_token) =>
			setSvCallback = () ->
				if @controller_.debug()
					console.log 'Socket requested sensor [' + sensor + '] SV set to [' + sv + ']'
				@controller_.setSv sensor, sv
			@checkPermission access_token, setSvCallback
			return

		# get sensor sv
		socket.on 'getsv', (sensor) =>
			sv = @controller_.getSv sensor
			data =
				sensor: sensor
				sv: sv
			socket.emit 'sv', data
			return

		# get a sensor's last reading
		socket.on 'getpv', (sensor) =>
			pv = @controller_.getPv sensor
			data = 
				sensor: sensor
				pv: pv
			socket.emit 'pv', data
			return

		# get a sensor's control mode
		socket.on 'getmode', (sensor) =>
			mode = @controller_.getMode sensor
			data = 
				sensor: sensor
				mode: mode
			socket.emit 'mode', data
			return

		# set a sensor's control mode
		socket.on 'setmode', (sensor, mode, access_token) =>
			setModeCallback = () ->
				if @controller_.debug()
					console.log 'Socket requested sensor [' + sensor '] set to mode [' + mode + ']'
				@controller_.setMode sensor, mode
			@checkPermission access_token, setModeCallback

		return


module.exports = Sockets
