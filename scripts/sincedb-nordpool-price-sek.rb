#!/usr/bin/env ruby
require './lib/init'
require './lib/activerecord-connect'

Pump::NordpoolPrice.new(Nordpool::PriceSEK, Price).run