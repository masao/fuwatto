#!/usr/bin/env ruby
# $Id$

require 'test/unit'

$:.push File.join( File.dirname( $0 ), ".." )
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

end
