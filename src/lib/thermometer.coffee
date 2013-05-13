# Raspberry Pi Fermentation temperature logging & control application
# (c) Joshua Farr <j.wgasa@gmail.com>

fs = require 'fs'

class Thermometer
	# base directory for temperature sensor data files
	basePath_: '/sys/bus/w1/devices/'
	deviceFile_: '/w1_slave'
	unit_: 'celsius'


	constructor: (units) ->
		@unit_ = units
		return


	# return an array of sensor serial numbers
	sensors: =>
		# get all directories matching pattern basePath_ + '28-*'
		files = fs.readdirSync @basePath_
		ids = []
		for entry in files
			pos = entry.indexOf '28-'
			if pos != -1
				ids.push entry.substr(pos + 3)
		return ids


	unit: (type) =>
		@unit_ = type
		return @


	raw: (sensorId) =>
		filename = @basePath_ + '28-' + sensorId + @deviceFile_
		data = String fs.readFileSync(filename)
		lines = data.split '\n'
		return lines


	temperature: (sensorId) =>
		reading = false
		# keep trying to read data until first line ends with 'YES'
		while not reading
			lines = @raw sensorId
			if lines[0].slice(lines[0].length - 3) == 'YES'
				reading = true
		# find 't='' in lines[1]
		pos = lines[1].indexOf 't='
		# get remainder of string
		if pos != -1
			rawTemp = parseFloat(lines[1].substr(pos + 2))
			temp = rawTemp / 1000.0
			if @unit_ == 'farenheight'
        		temp = temp * 9.0 / 5.0 + 32.0
        	return temp
        return null

module.exports = Thermometer
