# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>
# This file provides database services

# system includes
mongoose = require 'mongoose'

exports.establishConnection = () ->
  # establish db connection
  mongoose.connect 'mongodb://localhost:27017/brewtheory'
  return

exports.disconnect = () ->
	mongoose.disconnect()
