#!/usr/bin/env ruby
# $Id$

require "rubygems"
gem "test-unit"
require 'test/unit'
Test::Unit::AutoRunner.run(true, './test')
