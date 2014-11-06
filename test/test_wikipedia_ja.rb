#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "fuwatto.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_wikipedia_ja_search
      result = wikipedia_ja_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert_equal( result[:q], "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
end
