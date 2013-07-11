optimist = require('optimist').argv
mongoose = require 'mongoose'
bcrypt	 = require 'bcrypt'
db		 = require '../lib/services/db.js'

require '../lib/orm/user.js'


class UserTool
	run: (argv) ->
		if argv.add
			return @add argv.email, argv.password
	false

	add: (email, password) ->
		db.establishConnection()
		model = mongoose.model 'User'
		salt = bcrypt.genSaltSync 10
		hash = bcrypt.hashSync password, salt
		user = new model()
		user.email = email
		user.password = password
		user.salt = salt
		saveCallback = (err) ->
			return
		user.save saveCallback
		true


tool = new UserTool()
tool.run argv
