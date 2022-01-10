#!/usr/bin/env ruby
require 'bundler/setup'

require 'influxdb'
influxdb = InfluxDB::Client.new 'intermittency', host: ENV['INFLUX_HOST'], async: true,
                                chunk_size: 10000

require './lib/activerecord-connect'
require './app/models/entsoe_load'


if ARGV.length != 2
  $stderr.puts "#{$0} <from> <to>"
  exit 1
end
from = ARGV.shift
to = ARGV.shift


influxdb.query("SELECT * FROM entsoe_load WHERE time > '#{from}' AND time < '#{to}'") do |name, tags, values|
  $stderr.print "_"
  #require 'pry' ; binding.pry
  EntsoeLoad.insert_all values
end
puts "Done!"
