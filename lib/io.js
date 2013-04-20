// Generated by CoffeeScript 1.6.2
(function() {
  var IO, gpio,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  gpio = require('rpi-gpio');

  IO = (function() {
    IO.prototype.controlChannels_ = [];

    IO.prototype.debug_ = false;

    function IO(debug) {
      this.setup = __bind(this.setup, this);
      this.change = __bind(this.change, this);
      var debug_;

      debug_ = debug;
      return;
    }

    IO.prototype.change = function(channel, value) {
      if (this.debug_) {
        console.log('Channel ' + channel + ' value is now ' + value);
      }
      this.controlChannels_[channel].locked = false;
      this.controlChannels_[channel].enabled = value;
    };

    IO.prototype.setup = function(config) {
      var sensor, _i, _len, _ref;

      gpio.setMode(gpio.MODE_BCM);
      _ref = config.sensors;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sensor = _ref[_i];
        if (sensor.control !== "none") {
          gpio.setup(sensor.gpio, gpio.DIR_OUT);
          this.controlChannels_[sensor.gpio] = {
            enabled: false,
            locked: false
          };
        }
      }
      gpio.on('change', this.change);
    };

    IO.prototype.signalCallback = function(err) {
      if (err) {
        throw err;
      }
    };

    IO.prototype.signal = function(channel, state) {
      if (this.enabled(channel) !== state && !this.locked(channel)) {
        gpio.write(channel, state, this.signalCallback);
        this.controlChannels_[channel].locked = true;
      }
    };

    IO.prototype.enabled = function(channel) {
      return this.controlChannels_[channel].enabled;
    };

    IO.prototype.locked = function(channel) {
      return this.controlChannels_[channel].locked;
    };

    return IO;

  })();

  module.exports = IO;

}).call(this);