#!/usr/bin/env ruby
# $Id$

require "rubygems"
gem "test-unit"
require 'test/unit'
require "minitest/autorun"
Test::Unit::AutoRunner.run(true, './test')
