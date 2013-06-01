# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

mongoose = require 'mongoose'

require '../orm/profile.js'

# routes
# @param app the connect app
module.exports.routes = (app) ->

	# GET all profiles
	app.get '/profiles', (req, res) ->
		model = mongoose.model 'Profile'
		findCallback = (err, profiles) ->
			if not err
				res.send profiles
		model.find findCallback
		return

	# GET single profile by id
	app.get '/profiles/:id', (req, res) ->
		model = mongoose.model 'Profile'
		model.findById req.params.id, (err, profile) ->
			res.send profile
		return

	# POST create new profile
	app.post '/profiles', (req, res) ->
		model = mongoose.model 'Profile'
		profile = new model()
		profile.name = req.body.name
		profile.control_mode = req.body.control_mode
		profile.sensor = req.body.sensor
		profile.steps = req.body.steps
		profile.active = req.body.active
		profile.overrides = req.body.overrides

		saveCallback = (err) ->
			return
		profile.save saveCallback
		res.send profile

	# DELETE existing profile by id
	app.delete '/profiles/:id', (req, res) ->
		model = mongoose.model 'Profile'
		console.log 'deleting profile ' + req.params.id
		model.findByIdAndRemove req.params.id, (err, profile) ->
			if not err
				res.send profile

	# PUT update existing profile by id
	app.put '/profiles/:id', (req, res) ->
		model = mongoose.model 'Profile'
		model.findById req.params.id, (err, profile) ->
			profile.name = req.body.name
			profile.control_mode = req.body.control_mode
			profile.sensor = req.body.sensor
			profile.steps = req.body.steps
			oldState = profile.active
			profile.active = req.body.active
			profile.overrides = req.body.overrides

			if profile.active is true and oldState isnt true
				profile.start_time = new Date()
				controller = app.get 'controller'
				controller.state_[profile.sensor].profile = profile
				if controller.debug_
					console.log 'Bound active profile [' + profile.name + '] to sensor [' + profile.sensor + ']'

			profile.save (err) ->
				if not err
					res.send profile

	# end of route definitions
	return
