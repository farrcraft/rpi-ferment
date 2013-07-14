# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

argv 	 = require('optimist').argv
mongoose = require 'mongoose'
bcrypt	 = require 'bcrypt'
db		 = require '../lib/services/db.js'

require '../lib/orm/user.js'

# Tool for managing users in the MongoDB user collection
# Supported options:
# --add --email <email> --password <password>
# --list
# --delete <email>
class UserTool
	run: (argv) ->
		if argv.add
			return @add argv.email, argv.password
		else if argv.list
			return @list()
		else if argv.delete
			return @delete(argv.delete)
	false

	add: (email, password) ->
		db.establishConnection()
		model = mongoose.model 'User'
		salt = bcrypt.genSaltSync 10
		hash = bcrypt.hashSync password, salt
		user = new model()
		user.email = email
		user.password = hash
		user.salt = salt
		saveCallback = (err) ->
			db.disconnect()
			return
		user.save saveCallback
		true

	list: () ->
		db.establishConnection()
		model = mongoose.model 'User'
		findCallback = (err, users) ->
			if err
				db.disconnect()
				return
			for user in users
				console.log user.email
			db.disconnect()

		model.find findCallback

	delete: (email) ->
		db.establishConnection()
		model = mongoose.model 'User'
		deleteCallback = (err) ->
			db.disconnect()
			return
		model.findOneAndRemove { email: email }, deleteCallback


tool = new UserTool()
tool.run argv
