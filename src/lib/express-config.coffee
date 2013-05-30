# rpi-ferment
# Copyright(c) Josh Farr <j.wgasa@gmail.com>

Express 		= require 'express'
mongoose		= require 'mongoose'
logger			= require('./services/logger.js').logger
profileRouter 	= require './routes/profile.js'
db				= require './services/db.js'

#CORS middleware
allowedDomains = '*'
allowCrossDomain = (req, res, next) ->
	res.header 'Access-Control-Allow-Origin', allowedDomains
	res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
	res.header 'Access-Control-Allow-Headers', 'Content-Type'
	if req.method is 'OPTIONS'
		res.send 200
	else
		next()

exports.configure = (Express, app) ->
	app.configure ->
		logger.info 'Configuring application...'

		# Log responses to the terminal using Common Log Format.
		app.use Express.logger { buffer: true }
		app.use Express.methodOverride()
		app.use Express.bodyParser()
		app.use allowCrossDomain

		# need cookie parser for session support
		app.use Express.cookieParser()

		# Add a special header with timing information.
		app.use Express.responseTime()

		# routes
		profileRouter.routes app

		app.set 'log', 'logs/rpi-ferment.log'
		db.establishConnection()
		return


	# Dev config
	app.configure 'development', () ->
		logger.info 'Configuring development mode...'
		app.use Express.errorHandler { dumpExceptions: true, showStack: true }
		return

	# Production config
	app.configure 'production', () ->
		logger.info 'Configuring production mode...'
		app.use Express.errorHandler
		return


	# setup error handling

	NotFound = (msg) ->
		@name = 'NotFound'
		logger.info 'Not Found - ' + msg
		Error.call this, msg
		Error.captureStackTrace this, arguments.callee
		return


	NotFound.prototype.__proto__ = Error.prototype

	app.get '/404', (req, res) ->
		throw new NotFound 'page not found'
		return


	app.get '/500', (req, res) ->
		throw new Error 'keyboard cat!'
		return

	# error handler
	app.use (err, req, res, next) ->
		logger.error err
		if err instanceof NotFound
			res.send {status: 404, error: err}
		else
			res.send {status: 500, error: err}
		return
