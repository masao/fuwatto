#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "jstage.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_jstage_search
      result = jstage_search( "keyword" )
      assert( result )
      assert( result[:link] )
      assert( result[:q] )
      assert_equal( result[:q], "keyword" )
      assert( result[:totalResults] > 0 )
      assert( result[:entries].size > 0 )
   end
end

class TestJStage < Test::Unit::TestCase
   def setup
      ENV[ "REQUEST_METHOD" ] = "GET"
      @cgi = CGI.new( nil )
   end
   def test_execute
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :totalResults ] > 20 )
   end
   def test_execute2
      @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_execute_page
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result1 = jstage.execute
      @cgi.params["page"] = [ 1 ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result2 = jstage.execute
      assert( result1 )
      assert( result2 )
      assert( result1[ :totalResults ] > 0 )
      assert( result1[ :totalResults ] > 20 )
      assert( result2[ :entries ].size > 20 )
      # assert_not_equal( result1[ :entries ].size, result2[ :entries ].size )
      if result1[ :totalResults ] >= 40
         assert( result2[ :entries ].size > 40 )
      else
         assert_equal( result2[ :totalResults ], result2[ :entries ].size )
      end
   end
   def test_ssl
      @cgi.params["url"] = [ "https://addons.mozilla.org/ja/firefox/addon/1122" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      assert( result[ :entries ].size > 0 )
   end

   def test_json
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      $stdout = StringIO.new
      jstage.output( "jstage", result )
      $stdout.rewind
      json_str = $stdout.read
      assert( json_str )
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_not_nil( json )
      obj = JSON::Parser.new( json ).parse
      assert( obj )
      assert( obj[ "entries" ] )
      assert_equal( obj[ "entries" ].size, 20 )
      assert_equal( obj[ "database" ], "jstage" )
   end
   def test_json_callback
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      $stdout = StringIO.new
      jstage.output( "jstage", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "test({", json[0,6] )
   end
   def test_json_callback2
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test_test2" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      $stdout = StringIO.new
      jstage.output( "jstage", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "test_test2({", json[0,12] )
   end
   def test_json_callback3
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["callback"] = [ "test\"" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      $stdout = StringIO.new
      jstage.output( "jstage", result )
      $stdout.rewind
      json_str = $stdout.read
      json = json_str.split( /\r?\n\r?\n/ )[1]
      assert_equal( "{\"", json[0,2] )
      assert_not_equal( "test\"({", json[0,7] )
   end
   def test_json_count
      @cgi.params["url"] = [ "http://yahoo.co.jp" ]
      @cgi.params["format"] = [ "json" ]
      @cgi.params["count"] = [ 5 ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      $stdout = StringIO.new
      jstage.output( "jstage", result )
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
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      assert( result )
      assert_equal( result[ :database ], "jstage" )
   end
   def test_query_toolong
      # キャッシュファイル名がNAME_MAXを超えると、Errno::ENAMETOOLONG 例外が発生する。
      @cgi.params[ "text" ] = [ "消費 ホーム グループホーム 問題 火災 省庁 安全 認知 トヨタ 施設" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      result = jstage.execute
      assert( result )
      assert( result[ :totalResults ] > 0 )
      # assert( result[ :totalResults ] > 20 )
   end
   def test_nohit
      @cgi.params[ "text" ] = [ "testtesttesttest hogehogehogehoge" ]
      jstage = Fuwatto::JStageApp.new( @cgi )
      data = {}
      assert_raise( Fuwatto::NoHitError ) do
         data = jstage.execute
      end
      begin
         jstage.execute
      rescue Fuwatto::NoHitError
         data[ :error ] = Fuwatto::NoHitError
      end
      $stdout = StringIO.new
      assert_nothing_raised do
         jstage.output( "jstage", data )
      end
      $stdout.rewind
      result = $stdout.read
      assert( result =~ /error/m )
   end
end
