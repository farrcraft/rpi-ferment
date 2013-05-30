# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

mongoose    = require 'mongoose'

require '../orm/profile.js'

# routes
# @param app the connect app
module.exports.routes = (app) ->
	# GET method
	app.get '/profiles', (req, res) ->
		model = mongoose.model 'Profile'
		findCallback = (err, profiles) ->
			if not err
				res.send profiles

		model.find findCallback

		return

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

	app.delete '/profiles/:id', (req, res) ->
		model = mongoose.model 'Profile'
		console.log 'deleting profile ' + req.params.id
		model.findByIdAndRemove req.params.id, (err, profile) ->
			if not err
				res.send profile

	app.put '/profiles/:id', (req, res) ->
		model = mongoose.model 'Profile'
		model.findById req.params.id, (err, profile) ->
			profile.name = req.body.name
			profile.control_mode = req.body.control_mode
			profile.sensor = req.body.sensor
			profile.steps = req.body.steps
			profile.active = req.body.active
			profile.overrides = req.body.overrides

			profile.save (err) ->
				if not err
					res.send profile

	# end of route definitions
	return
