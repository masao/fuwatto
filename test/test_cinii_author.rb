#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'

$:.push File.join( File.dirname( __FILE__ ), ".." )
require "cinii-author.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_cinii_author_search
      #p cinii_author_search( "a" )
      result = cinii_author_search( "高久雅生" )
      assert_not_equal( "", result[ :entries ].first.has_key?( :affiliation ) )
      result[ :entries ].each do |au|
         assert_match( /\/nrid\/\w+$/, au[ :url ] )
      end
   end
end

class TestCiniiAuthor < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )
      assert( result[ :entries ].size >= 20 )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
      @cgi.params[ "text" ] = [ "情報検索プロトコル Z39.50 sru srw" ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end

   def test_execute_page
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result1 = cinii.execute
      $stdout = StringIO.new
      assert_nothing_raised do
         cinii.output( "cinii", result1 )
      end
      $stdout.rewind
      output1 = $stdout.read

      @cgi.params["page"] = [ 1 ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result2 = cinii.execute
      $stdout = StringIO.new
      assert_nothing_raised do
         cinii.output( "cinii", result2 )
      end
      $stdout.rewind
      output2 = $stdout.read

      assert( result1 )
      assert( result1[ :totalResults ] > 0 )
      assert( result1[ :totalResults ] > 20 )      
      assert( result2[ :entries ].size > 20 )
      assert_not_equal( output1, output2 )
   end

   def test_execute_masao
      @cgi.params["url"] = [ "http://masao.jpn.org/profile.html" ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result = cinii.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )      
      assert( result[ :entries ].size > 20 )
      #p result[ :entries ].map{|e| e[:author] }
      assert( result[ :entries ].find{|e| e[ :author ] === "高久 雅生" } )
   end
end
