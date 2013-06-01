# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>

mongoose	= require 'mongoose'
Schema		= mongoose.Schema


# Schema for mongo fermentation profile collection
# override actions:
#	on - force heater on
#	off - force heater off
#	resume - resume current profile step
Profile = new Schema

Profile.add
	name: 
		type: String
		required: true
	control_mode: String
	sensor: String
	start_time: Date
	steps: [
		name: String
		duration: Number
		unit: String
		temperature: Number
		order: Number
	]
	overrides: [
		action: String
		time: Date
	]
	history: [
		action: String
		state: String
		time: Date
	]
	updated_at: Boolean
	active: Boolean
	created_at:
		type: Date, 
		default: Date.now


mongoose.model 'Profile', Profile
