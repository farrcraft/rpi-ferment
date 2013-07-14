# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

argv 	 = require('optimist').argv
mongoose = require 'mongoose'
bcrypt	 = require 'bcrypt'
hashlib  = require 'hashlib'
fs 		 = require 'fs'
Buffer 	 = require('buffer').Buffer
db		 = require '../lib/services/db.js'

require '../lib/orm/user.js'

# Tool for managing users in the MongoDB user collection
#
# Supported options:
#
# Add a new user:
# --add --email <email> --password <password>
#
# List existing users:
# --list
#
# Delete an existing user
# --delete <email>
#
# Generate an access token
# --token
#
class UserTool
	run: (argv) ->
		if argv.add
			return @add argv.email, argv.password
		else if argv.list
			return @list()
		else if argv.delete
			return @delete(argv.delete)
		else if argv.token
			@generateToken()
	false

	add: (email, password) ->
		db.establishConnection()
		model = mongoose.model 'User'
		salt = bcrypt.genSaltSync 10
		hash = bcrypt.hashSync password, salt
		user = new model()
		user.email = email
		user.password = hash
		token = @generateToken()
		user.access_token = token
		# the hash starts with the salt value so storing the salt separately is redundant...
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

	generateToken: () ->
		howMany = 100
		bytes = new Buffer howMany
		fd = fs.openSync '/dev/random', 'r'
		fs.readSync fd, bytes, 0, howMany
		fs.closeSync fd
		hash = hashlib.sha512 bytes.toString()
		token = hash.substring 0, 40
		token


tool = new UserTool()
tool.run argv
