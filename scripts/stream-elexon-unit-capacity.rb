#!/usr/bin/env ruby
# coding: utf-8
require './lib/init'
require './lib/activerecord-connect'
logger = SemanticLogger[$0]

Elexon::UnitCapacity.cli(ARGV)
