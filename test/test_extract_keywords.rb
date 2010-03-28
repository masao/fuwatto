#!/usr/bin/env ruby
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
end
