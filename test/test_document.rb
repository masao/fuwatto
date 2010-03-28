#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "fuwatto.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_document
		text = "test test1 test2"
		vector = Document.new( text )
		assert( vector )
		assert_equal( 3, vector.size )
		
		text = "test test test"
		vector2 = Document.new( text )
		assert_equal( 1, vector2.size )

		text = "text text1 text2"
		vector3 = Document.new( text )
		
		assert( vector.sim( vector2 ) > vector.sim( vector3 ) )
		STDERR.puts vector.sim( vector2 )
		STDERR.puts vector.sim( vector3 )

		corpus = [ "吾輩は猫である", "吾輩は犬である", "夏目漱石　坊っちゃん" ]
		vector = Document.new( corpus[0] )
		vector2 = Document.new( corpus[1] )
		vector3 = Document.new( corpus[2] )
		STDERR.puts vector.sim( vector2 )
		STDERR.puts vector.sim( vector3 )
		assert( vector.sim( vector2 ) > vector.sim( vector3 ) )
		STDERR.puts vector.sim( vector2 )
		STDERR.puts vector.sim( vector3 )
   end
end
