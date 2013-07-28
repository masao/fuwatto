#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require 'test/unit'
#require 'ftools'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "crd.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_crd_search
      result = crd_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert( result[:q] == "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
   def test_crd_search2
      result = crd_search2( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert( result[:q] == "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
end

class TestCRD < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::CRDApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      #assert( result[ :totalResults ] > 20 )
   end
   def test_output
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::CRDApp.new( @cgi )
      result = app.execute
      $stdout = File.open( "/dev/null", "w" )
      app.output( "crd", result )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      app = Fuwatto::CRDApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_execute_page
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["page"] = [ 1 ]
      cinii = Fuwatto::CRDApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      #assert( result[ :totalResults ] > 20 )
   end
end
