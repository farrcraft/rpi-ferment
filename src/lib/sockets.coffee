# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

http 		 = require 'http'
socketio	 = require 'socket.io'

class Sockets
	controller_: null
	io_: null

	constructor: (controller) ->
		@controller_ = controller

	httpHandler: (req, res) ->
		res.writeHead 200
		res.end ''
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
			socket.emit 'gpio', state
			return

		# set gpio state for channel
		socket.on 'setgpio', (channel, state) =>
			if @controller_.debug()
				console.log 'Socket requested GPIO channel [' + channel + '] set to state [' + state + ']'
			@controller_.setGpio channel, state
			return

		# set sensor sv
		socket.on 'setsv', (sensor, sv) =>
			if @controller_.debug()
				console.log 'Socket requested sensor [' + sensor + '] SV set to [' + sv + ']'
			@controller_.setSv sensor, sv
			return

		# get sensor sv
		socket.on 'getsv', (sensor) =>
			sv = @controller_.getSv sensor
			socket.emit 'sv', sv
			return

		# get a sensor's last reading
		socket.on 'getpv', (sensor) =>
			pv = @controller_.getPv sensor
			socket.emit 'pv', pv
			return

		# get a sensor's control mode
		socket.on 'getmode', (sensor) =>
			mode = @controller_.getMode sensor
			socket.emit 'mode', mode
			return

		# set a sensor's control mode
		socket.on 'setmode', (sensor, mode) =>
			if @controller_.debug()
				console.log 'Socket requested sensor [' + sensor '] set to mode [' + mode + ']'
			@controller_.setMode sensor, mode

		return


module.exports = Sockets
