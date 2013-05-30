# rpi-ferment-frontend
# Copyright(c) Josh Farr <j.wgasa@gmail.com>

# load framework
express = require 'express'

# load application configuration object
config = require './express-config.js'

# create app
app = module.exports = express()

# all of the app-specific setup happens inside the config module
config.configure express, app

