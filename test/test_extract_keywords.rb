#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "fuwatto.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_extract_keywords_mecab
	text = "test test1 test2"
	result = extract_keywords_mecab( text )
	#p result
	assert( result )
	assert( result.size > 0 )
	assert_equal( 3, result.size )
	assert_equal( "test", result[0][0] )
   end
   def test_mecab_1
      res, = http_get( URI.parse("http://crd.ndl.go.jp/GENERAL/servlet/detail.reference?id=1000059361") )
      str = res.body
      content = ExtractContent::analyse( str )
      #STDERR.puts content.join.toeuc
      result = extract_keywords_mecab( content.join( "\n" ) )
      assert( result )
      # $KCODE = "u"
      # STDERR.puts result.inspect
      # puts result
      assert_equal( [], result.map{|e| e[0] }.grep( /『/ ) )
   end
end
