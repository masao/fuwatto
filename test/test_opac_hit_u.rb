#!/usr/bin/env ruby
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "opac-hit-u.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_opac_hit_u_search
      result = opac_hit_u_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert_equal( result[:q], "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
      assert( result[:totalResults] >= result[:entries].size )
      if result[:entries].size < 20
         assert( result[:entries].size == result[:totalResults] )
      end
   end
end

class TestOPACHitU < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute_page
      @cgi.params["text"] = [ "keyword" ]
      @cgi.params["page"] = [ 1 ]
      app = Fuwatto::OPACHitUApp.new( @cgi )
      result = app.execute
      #p result[ :entries ].size
      assert( result )
      assert( result[ :totalResults ] > 20 )
      assert( result[ :entries ].size > 20 )
      assert( result[ :entries ].size == 40 )
   end
   def test_json
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      opac = Fuwatto::OPACHitUApp.new( @cgi )
      result = opac.execute
      $stdout = StringIO.new
      opac.output( "opac_hit_u", result )
      $stdout.rewind
      json_str = $stdout.read
      assert( json_str )
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_not_nil( json )
      obj = JSON::Parser.new( json ).parse
      assert( obj )
      assert_equal( "opachitu", obj[ "database" ] )
      assert( obj[ "entries" ] )
      assert( obj[ "entries" ].size > 0 )
   end
   def test_nohit
      @cgi.params[ "text" ] = [ "testtesttest testtesttest" ]
      opac = Fuwatto::OPACHitUApp.new( @cgi )
      data = {}
      assert_raise( Fuwatto::NoHitError ) do
         data = opac.execute
      end
      begin
         opac.execute
      rescue Fuwatto::NoHitError
         data[ :error ] = Fuwatto::NoHitError
      end
      $stdout = StringIO.new
      assert_nothing_raised do
         opac.output( "opac", data )
      end
      $stdout.rewind
      result = $stdout.read
      assert( result =~ /error/m )
   end
end
