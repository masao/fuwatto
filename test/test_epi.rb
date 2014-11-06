#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "epi.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_epi_search
      result = epi_search( "多読" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert_equal( result[:q], "多読" )
      assert( result[:totalResults] > 20 )
      assert( result[:entries].size > 0 )
   end
end

class TestEpi < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_execute3
      @cgi.params[ "url" ] = [ "http://www.asahi.com/paper/editorial.html" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_execute_page
      @cgi.params["text"] = [ "図書館" ]
      @cgi.params["page"] = [ 1 ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 20 )
      assert( result[ :entries ].size > 20 )
      assert( result[ :entries ].size == 40 )
   end
   def test_ssl
      @cgi.params["url"] = [ "https://addons.mozilla.org/ja/firefox/addon/1122" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :entries ].size > 0 )
   end

   def test_json
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      $stdout = StringIO.new
      epi.output( "epi", result )
      $stdout.rewind
      json_str = $stdout.read
      assert( json_str )
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_not_nil( json )
      obj = JSON::Parser.new( json ).parse
      assert( obj )
      assert( obj[ "entries" ] )
      assert( obj[ "entries" ].size > 0 )
      assert_equal( obj[ "database" ], "epi" )
   end
   def test_json_callback
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      $stdout = StringIO.new
      epi.output( "epi", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "test({", json[0,6] )
   end
   def test_json_callback2
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test_test2" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      $stdout = StringIO.new
      epi.output( "epi", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "test_test2({", json[0,12] )
   end
   def test_json_callback3
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test\"" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      $stdout = StringIO.new
      epi.output( "epi", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "{\"", json[0,2] )
      assert_not_equal( "test\"({", json[0,7] )
   end
   def test_json_count
      @cgi.params["url"] = [ "http://ja.wikipedia.org/wiki/%E6%95%99%E8%82%B2" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["count"] = [ 5 ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      $stdout = StringIO.new
      epi.output( "epi", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      obj = JSON::Parser.new( json ).parse
      assert( obj )
      assert_equal( 5, obj["entries"].size )
      assert_not_equal( 20, obj["entries"].size )
   end
   def test_param_database
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert_equal( result[ :database ], "epi" )
   end
   def test_query_toolong
      # キャッシュファイル名がNAME_MAXを超えると、Errno::ENAMETOOLONG 例外が発生する。
      @cgi.params[ "text" ] = [ "消費 ホーム グループホーム 問題 火災 省庁 安全 認知 トヨタ 施設" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      result = epi.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_nohit
      @cgi.params[ "text" ] = [ "testtesttest testtesttest" ]
      epi = Fuwatto::EpiApp.new( @cgi )
      data = {}
      assert_raise( Fuwatto::NoHitError ) do
         data = epi.execute
      end
      begin
         epi.execute
      rescue Fuwatto::NoHitError
         data[ :error ] = Fuwatto::NoHitError
      end
      $stdout = StringIO.new
      assert_nothing_raised do
         epi.output( "epi", data )
      end
      $stdout.rewind
      result = $stdout.read
      assert( result =~ /error/m )
   end
end
