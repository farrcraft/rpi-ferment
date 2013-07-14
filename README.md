# rpi-ferment

A tool to monitor temperature sensor data, log it and make IO responses.


## Dependencies

- [CoffeeScript](http://coffeescript.org/)
- [StatsD](https://github.com/etsy/statsd/)
- [node-statsd](https://github.com/sivy/node-statsd)
- [Optimist](https://github.com/substack/node-optimist)
- [rpi-gpio.js](https://github.com/JamesBarwell/rpi-gpio.js)
- [rpi-pid](https://github.com/sigsegv42/rpi-pid)
- [forever](https://github.com/nodejitsu/forever)
- [Mongoose](http://mongoosejs.com/)
- [Express](http://expressjs.com/)
- [Socket.IO](http://socket.io/)
- [bcrypt](https://github.com/ncb000gt/node.bcrypt.js/)


The _make modules_ command uses npm to install all of the application dependencies.  All modules are installed locally in the node_modules directory except for forever.  Forever is preferred to be installed globally and requires sudo permission to install this way.


## Installation

Invoking _make_ or _make build_ from the root directory compiles the CoffeeScript source.  Coffeescript must already be installed in the local node_modules directory for this to work.


## Configuration

Before invoking the application in continuous polling mode, it needs to be configured.  The source of the configuration data is in the *src/lib/config.coffee* file.  _make_ should be rerun after any changes to this file are made in order to regenerate the corresponding *lib/config.js* file.

### pollFrequency

Defines in milliseconds how often the sensors are polled.

### sensorUnit

Defines whether readings are taken in *celsius* or *farenheight*

### sensors

An array with a block defined for each sensor that will be polled.

#### name

A short descriptive name for the sensor.  The name is used when logging the temperature data.

#### id

The serial number of the temperature sensor.  Refer to the **Usage** section for how to obtain these values.

#### gpio

The GPIO channel that any control signals will be generated on for the sensor.  The channel number is different than the actual pin number that it is connected to (referred to as BCM mode by the gpio module).  This setting can be omitted if the *control* parameter is set to *none*.

#### sv

The temperature set value used for determining when to send a control signal.  This value should be in the same units as the *sensorUnit* setting indicates.  This setting can be omitted if the *control* parameter is set to *none*. 

#### control

The direction of temperature change that the associated GPIO channel controls.  Valid values are *heater* and *chiller*.  When set to *heater* the GPIO will be turned on if the PV is below the SV.  The *chiller* setting will turn the GPIO on when the PV is above the SV.

#### cycle

The number of seconds that a GPIO channel must remain off before it can be turned back on again.  When controlling a fridge or freezer, the power should be turned on and off less frequently in order to maintain the life of the compressor.  This value should be set to at least 10-15 minutes (x60) for those devices.  Heating elements typically don't require a cool down period.

## Usage

When invoked without any options, the application enters continuous polling mode and does not exit.  The frequency of polling and list of sensors to be polled are defined in the *lib/config.js* file.

The default monitoring mode creates a socket.io server on port 6001 and an Express app server on port 3010.  These ports are customizable in the *src/lib/config.coffee* source file.  Any changes to these ports must also be mirrored in the frontend application.

The list of sensors needs to be configured with the actual sensor ids before invoking the monitoring mode.  While the serial numbers are printed directly on the sensors, it is much easier and less error prone to query them programmatically instead.  Invoking the application with the *--sensors* option does this, printing the serial number of each connected temperature sensor.

``` bash
  $ node monitor.js --sensors
```

It is also possible to query a single sensor for the current temperature once and then immediately exit.  Using the *--query* option and passing it the serial number of the sensor accomplishes this.

``` bash
   $ node monitor.js --query 000004bd9529
```
### Additional CLI options

* --debug - generate more verbose output on stdout
* --nolog - do not send any data to statsd

### Output Control

GPIO channels can be toggled by using the *--control <gpio>* option with either *--enable* or *--disable*.

``` bash
  $ node monitor.js --control 8 --enable
```

The current state of GPIO channels can be queried by using the *--status <gpio>* option.

``` bash
  $ node monitor.js --status 8
```

## Access Control

The Express and Socket.IO API's only allow modifications to be made by authorized users that provide a valid access token with the calls to those methods.  In the Express API this is done via HTTP authentication headers.  Socket.IO calls should pass the token directly as one of the data parameters.


## User Management

User management is done using the separate *tools/user-tool.js* command.  Users are stored in the user collection of the mongodb.  Each user is assigned a unique access token at the time of creation.

The following commands are supported:


### Add User
* --add --email <email> --password <password>

### List Users

* --list

### Delete User

* --delete <email>

### Generate Access Token

* --token


## Express API

The Express.js server that is started in the default monitoring mode provides a simple RESTful API for interacting with fermentation profiles.  The default configuration specifies that it listens on port *3010*.

### [POST] /session

Perform user authentication.  The request payload should include the user email address and raw password.  If authentication is successful, then the user's access token is sent in the response payload. 

### [GET] /profiles

Retrieve an array of all saved fermentation profiles.

### [GET] /profiles/:id

Retrieve a single saved fermentation profile by its primary key id.

### [POST] /profiles

Save a new fermentation profile.

### [DELETE] /profiles/:id

Delete an existing fermentation profile by its primary key id.

### [PUT] /profiles/:id

Update an existing fermentation profile by its primary key id.


## Socket.IO API

The Socket.IO server that is started in the default monitoring mode listens on port *6001* by default.  Clients connected to this realtime event server can emit events that either query or modify the current state of the monitoring server.


### config

Request the current sensor configuration data.

### getgpio <channel>

Request the current GPIO state of a channel.

### setgpio <channel> <state>

Set the GPIO state of a channel to the specified state.

### setgpio <data>

This event is emitted by the server anytime that the GPIO state changes.  The data includes the *sensor* and new *state*.

### getsv <sensor>

Get the current SV of a sensor.

### setsv <sensor> <sv>

Set the current SV of a sensor.  

### setsv <data>

This event is emitted by the server anytime that the SV changes (e.g., updates due to profile step changes).  The data includes the *sensor* and new sv *value*.

### getpv <sensor>

Get the most recent PV reading from a sensor.

### getmode <sensor>

Get the current control mode for a sensor.

### setmode <sensor> <mode>

Set the current control mode for a sensor.

### setpv <data>

This event is emitted when a new PV is sampled.  The data contains the *sensor* and *pv* values.
