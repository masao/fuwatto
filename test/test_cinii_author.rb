#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "cinii-author.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_cinii_author_search
      #p cinii_author_search( "a" )
      result = cinii_author_search( "高久雅生" )
      assert_not_equal( "", result[ :entries ].first[ :affiliation ] )
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
      @cgi.params["page"] = [ 1 ]
      cinii = Fuwatto::CiniiAuthorApp.new( @cgi )
      result2 = cinii.execute
      assert( result1 )
      assert( result1[ :totalResults ] > 0 )
      assert( result1[ :totalResults ] > 20 )      
      assert( result2[ :entries ].size > 20 )
      assert_not_equal( result1[ :entries ], result2[ :entries ] )
      if result1[ :totalResults ] >= 40
         assert_equal( 40, result2[ :entries ].size )
      else
         assert_equal( result2[ :totalResults ], result2[ :entries ].size )
      end
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
