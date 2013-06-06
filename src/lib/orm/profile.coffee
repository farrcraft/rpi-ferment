# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>

mongoose	= require 'mongoose'
Schema		= mongoose.Schema


# Schema for mongo fermentation profile collection
# overrides[n].action:
#	on - force heater on
#	off - force heater off
#	resume - resume current profile step
# steps[n].unit:
#	days
#	hours
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
		completed: Boolean
		start_time: Date
		end_time: Date
		active: Boolean
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
