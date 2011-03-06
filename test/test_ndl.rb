#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "ndl.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_ndl_search
      result = ndl_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert( result[:q] == "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
   def test_ndl_search_isbn
      result = ndl_search( "yahoo" )
      assert( result )
      assert( result[:entries].size > 0 )
      isbncount = 0
      result[:entries].each do |e|
         isbncount += 1 if e[ :isbn ]
      end
      assert( isbncount > 0, "there is no isbn entry." )
      #p [ result[:entries].size, isbncount ]
   end
end

class TestNDL < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::NDLApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )
   end
   def test_output
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      app = Fuwatto::NDLApp.new( @cgi )
      result = app.execute
      $stdout = File.open( "/dev/null", "w" )
      app.output( "ndl", result )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      app = Fuwatto::NDLApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_execute_page
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["page"] = [ 1 ]
      cinii = Fuwatto::NDLApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )
   end
end
