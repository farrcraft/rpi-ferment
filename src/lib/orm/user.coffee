# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>

mongoose	= require 'mongoose'
Schema		= mongoose.Schema


User = new Schema

User.add
	email: 
		type: String
		required: true
	password: 
		type: String
		required: true
	salt: 
		type: String
		required: true
	access_token:
		type: String
	updated_at: Boolean
	active: Boolean
	created_at:
		type: Date, 
		default: Date.now


mongoose.model 'User', User
