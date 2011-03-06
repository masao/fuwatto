#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "springer.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_springer_search
      result = springer_search( "keyword" )
      assert( result )
      assert( result[:q] )
      assert_equal( result[:q], "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
      result[ :entries ].each do |e|
         p e[:title]
         assert( e[ :doi ] )
         assert( e[:isbn] || e[:volume] )
      end
   end
end

class TestSpringer < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      springer = Fuwatto::SpringerApp.new( @cgi )
      result = springer.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      #assert( result[ :totalResults ] > 20 )
      #assert_equal( 20, result[ :entries ].size )
   end
   def test_execute_count
      @cgi.params["url"] = [ "http://www.asahi.com/english/" ]
      [ 5, 100, 200, 201 ].each do |count|
         @cgi.params["count"] = [ count ]
         springer = Fuwatto::SpringerApp.new( @cgi )
         result = springer.execute
         assert( result )
         assert( result[ :totalResults ] > 0 )
         assert( result[ :totalResults ] >= count )
         assert( result[ :entries ].size >= count, "Results size(#{ result[:entries].size }) is smaller than count(#{count})." )
      end
   end
end
