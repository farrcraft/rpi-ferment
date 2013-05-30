# rpi-ferment
# Copyright(c) Joshua Farr <j.wgasa@gmail.com>

winston         = require 'winston'

module.exports.logger = new (winston.Logger)({
  transports: [
    new (winston.transports.File)({ filename: 'logs/rpi-ferment.log' })
  ]
})

