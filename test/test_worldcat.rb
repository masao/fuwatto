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
      result[ :entries ].each do |e|
         assert( e[ :title ] )
         case e[:url]
         when /\/(315888140|635341692)/o
            next
         else
            #p e[:title]
            assert( e[:isbn] )
         end
      end
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
      $stdout = File.open( "/dev/null", "w" )
      app.output( "worldcat", result )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      app = Fuwatto::WorldcatApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   # jawp:百里飛行場
   def test_count
      # @cgi.params["url"] = [ "http://ja.wikipedia.org/wiki/%E7%99%BE%E9%87%8C%E9%A3%9B%E8%A1%8C%E5%A0%B4" ]
      @cgi.params["text"] = [ "wiktionary" ]
      app = Fuwatto::WorldcatApp.new( @cgi )
      result = app.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] < 20 )
      assert( result[ :totalResults ] < app.count )
      assert_equal( result[ :totalResults ], result[ :entries ].size )
      $stdout = File.open( "/dev/null", "w" )
      assert_nothing_raised do
         app.output( "worldcat", result )
      end
   end
end
