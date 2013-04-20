# rpi-ferment

A tool to monitor temperature sensor data, log it and make IO responses.


## Dependencies

- coffee-script
- statsd
- node-statsd
- optimist
- rpi-gpio
- rpi-pid
- forever

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

The control mode can be *none*, *manual*, or *pid*.  

##### none

When set to **none**, the *gpio* and *sv* sensor parameters will be ignored and no control signals will be generated.

##### manual

Manual control mode sends a control signal to turn on the *gpio* channel when the temperature sensor reading is below the *sv* temperature.  When the temperature reading is at or above the *sv* value then a control signal is sent to turn off the configured *gpio* channel.

##### pid

PID control mode uses a PID controller algorithm to generate the control signals.


## Usage

When invoked without any options, the application enters continuous polling mode and does not exit.  The frequency of polling and list of sensors to be polled are defined in the *lib/config.js* file.

The list of sensors needs to be configured with the actual sensor ids before invoking this mode.  While the serial numbers are printed directly on the sensors, it is much easier to query them programmatically instead.  Invoking the application with the *--sensors* option does this, printing the serial number of each connected temperature sensor.

``` bash
  $ node index.js --sensors
```

It is also possible to query a single sensor for the current temperature once and then immediately exit.  Using the *--query* option and passing it the serial number of the sensor accomplishes this.

``` bash
   $ node index.js --query 000004bd9529
```
