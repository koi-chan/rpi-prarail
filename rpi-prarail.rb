#!/usr/bin/ruby

require 'bundler/setup'
require 'pi_piper'

PIN_IN1 = 23
PIN_IN2 = 24

SLEEP = 0.01

=begin
MODE = 0 (IN/IN)
IN1 IN2 OUT1 OUT2
  0   0    -    -  空転
  0   1    L    H  逆進
  1   0    H    L  前進
  1   1    L    L  回生ブレーキ

MODE = 1 (PHASE/ENABLE)
IN1 IN2 OUT1 OUT2
  0   x    L    L  回生ブレーキ
  1   1    L    H  逆進
  1   0    H    L  前進
=end

class RpiPrarail
  attr_reader :pin_in1
  attr_reader :pin_in2
  attr_reader :pwm
  attr_reader :coast

  def initialize
    @pin_in1 = PiPiper::Pin.new(pin: PIN_IN1, direction: :out)
    @pin_in2 = PiPiper::Pin.new(pin: PIN_IN2, direction: :out)
    @pwm = nil
    @coast = true

    stop
  end

  def pwm_setting(freq, duty)
    @pwm = PWM.new(freq: freq, duty: duty)
  end

  def start
    if(@pwm)
      loop do
        _start
        sleep(@pwm.pulse_on - SLEEP)
        stop
        sleep(@pwm.pulse_off - SLEEP)
      end
    else
      _start
    end
  end

  def stop
    @coast ? _coast : _brake
  end

  def _coast
    @pin_in1.off
    @pin_in2.off
    _sleep
  end

  def _forward
    @pin_in1.on
    @pin_in2.off
    _sleep
  end

  def _reverse
    @pin_in1.off
    @pin_in2.on
    _sleep
  end

  def _brake
    @pin_in1.on
    @pin_in2.on
    _sleep
  end

  private

  def _sleep
    sleep(SLEEP)
  end
end

class RpiPrarail::PWM
  attr_reader :freq
  attr_reader :duty
  attr_reader :pulse_on
  attr_reader :pulse_off

  def initialize(new_freq: 50.0, new_duty: 0.0)
    freq = new_freq
    duty = new_duty
  end

  def duty=(new_duty)
    @duty = new_duty if(new_duty >= 0.0 && new_duty <= 100.0)
    get_pulse
  end

  private

  def freq=(new_freq)
    @freq = new_freq if(new_freq > 0.0)
  end

  def get_pulse
    @pulse_on = 1 / freq * duty / 100
    @pulse_off = 1 - @pulse_on
  end
end

prarail = RpiPrarail.new
