# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

mongoose = require 'mongoose'
bcrypt	 = require 'bcrypt'

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
				if bcrypt.compareSync req.body.password, result.password
					# success
					res.send { id: result._id }
				else
					# auth failure
					res.send { }
		model.findOne { email: req.body.email }, findCallback
		return