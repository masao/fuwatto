#!/usr/bin/env ruby
# $Id$

require "minitest/autorun"
#require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "dpla.rb"

class TestFuwatto < MiniTest::Test
   include Fuwatto
   def test_dpla_search
      result = dpla_search( "keyword" )
      assert( result )
      assert( result[:q] )
      assert_equal( result[:q], "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
      result[ :entries ].each do |e|
         assert( e[ :title ] )
         #assert( e[ :author ] )
      end
   end
end

class TestDPLA < MiniTest::Test
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      dpla = Fuwatto::DPLAApp.new( @cgi )
      result = dpla.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      #assert( result[ :totalResults ] > 20 )
      #assert_equal( 20, result[ :entries ].size )
   end
   def test_execute_count
      @cgi.params["url"] = [ "https://en.wikipedia.org/wiki/Barack_Obama" ]
      [ 5, 50, 51, 60, 61 ].each do |count|
         @cgi.params["count"] = [ count ]
         dpla = Fuwatto::DPLAApp.new( @cgi )
         result = dpla.execute
         assert( result )
         assert( result[ :totalResults ] > 0 )
         assert( result[ :totalResults ] >= count )
	 ## TODO
         #assert( result[ :entries ].size >= count, "Results size(#{ result[:entries].size }) is smaller than count(#{count})." )
      end
   end
end
