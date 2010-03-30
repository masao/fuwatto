#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
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

class TestCinii < Test::Unit::TestCase
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
end
