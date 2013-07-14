# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

mongoose = require 'mongoose'

require '../orm/user.js'

# routes
# @param app the connect app
module.exports.routes = (app) ->

	# POST auth a user
	app.post '/session', (req, res) ->
		model = mongoose.model 'User'
		findCallback = (error, result) ->
			if error
				return
			if result
				if bcrypt.compare_sync req.password, result.password
					# success
					res.send { id: result._id }
				else
					# auth failure
					res.send { }
		model.findOne { email: req.email }, findCallback
		return