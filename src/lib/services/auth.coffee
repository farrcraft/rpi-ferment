# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>

Buffer 		= require('buffer').Buffer
mongoose    = require 'mongoose'
db          = require './db.js'

require '../orm/user.js'

# Parse an http auth header. The header looks something like:
# authorization: 'Basic ab83feDQIZ82C82kd8CHQD=='
# @param req Request object
exports.getAuthToken = (req) ->
	# get the auth header
	header = req.headers['authorization'] || ''
	parts = header.split /\s+/
	token = parts.pop() || ''
	method = parts.shift() || ''
	if method isnt 'Bearer'
		return null
	# header is base64 encoded, so use a buffer to decode it
	auth = new Buffer(token, 'base64').toString()
	return auth


exports.checkAuthToken = (token, callback) ->
	model = mongoose.model 'User'
	authCallback = (err, model) ->
		if model isnt undefined
			callback true
		else
			callback false
	model.findOne { access_token: token }, authCallback