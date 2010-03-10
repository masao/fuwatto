#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "worldcat.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_worldcat_search
      result = worldcat_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert( result[:q] == "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
end

class TestWorldcat < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::WorldcatApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )
   end
   def test_output
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::WorldcatApp.new( @cgi )
      result = app.execute
      html = app.output( "worldcat", result )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      app = Fuwatto::WorldcatApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
end
