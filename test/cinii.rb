#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "cinii.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_cinii_search
      result = cinii_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert( result[:q] == "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
end

class TestCinii < Test::Unit::TestCase
   def setup
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      cinii = Fuwatto::CiniiApp.new( @cgi )
      assert( cinii.execute )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      cinii = Fuwatto::CiniiApp.new( @cgi )      
      assert( cinii.execute )
   end
end
