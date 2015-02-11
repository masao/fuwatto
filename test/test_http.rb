#!/usr/bin/env ruby
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "cinii.rb"

class TestFuwattoHTTP < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end

   def test_about
      @cgi.params["url"] = [ "about:blank" ]
      cinii = Fuwatto::CiniiApp.new( @cgi )
      result = {}
      assert_nothing_raised do
         result = cinii.execute
      end
      assert_equal( :UnsupportedURI, result[ :error ] )
   end

   def test_cookie
     @cgi.params[ "url" ] = [ "http://www.nytimes.com/2015/02/12/us/obama-war-authorization-congress.html" ]
      cinii = Fuwatto::CiniiApp.new( @cgi )
      result = {}
      assert_nothing_raised do
         result = cinii.execute
      end
   end

end
