#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require 'test/unit'

$:.unshift File.join( File.dirname( __FILE__ ), ".." )
require "fuwatto.rb"

class TestFuwatto < Test::Unit::TestCase
   include Fuwatto
   def test_document
      text = "test test1 test2"
      vector = Document.new( text )
      assert( vector )
      assert_equal( 1, vector.size )
      
      text = "test test test"
      vector2 = Document.new( text )
      assert_equal( 1, vector2.size )

      text = "text text1 text2"
      vector3 = Document.new( text )
      
      assert( vector.sim( vector2 ) > vector.sim( vector3 ) )
      #STDERR.puts vector.sim( vector2 )
      #STDERR.puts vector.sim( vector3 )

      corpus = [ "自分は本からの理窟でなく、日常の生活から、体でそれを学んだ。 宮本百合子『若者の言葉（『新しきシベリアを横切る』）』 ",
                 "ただ寄り添うばかりでなく、二人よったことで二つの人間としての善意をもっと強いものにし、世俗的な意味ばかりでなしに生活の向上をさせて行きたいと思う人々も多いに相異ない。 宮本百合子『これから結婚する人の心持』",
                 "渋沢栄一 夏目漱石　坊っちゃん",
                 "自分は本からの理窟でなく、日常の生活から、体でそれを学んだ。 宮本百合子『若者の言葉（『新しきシベリアを横切る』）』 ",
               ]
      vector = Document.new( corpus[0] )
      vector2 = Document.new( corpus[1] )
      vector3 = Document.new( corpus[2] )
      #p vector.sim( vector2 )
      #p vector.sim( vector3 )
      assert( vector.sim( vector2 ) > vector.sim( vector3 ) )

      # term_weight paramerter:
      vector1 = Document.new( corpus[0], :mecab, { :term_weight => :tf } )
      p vector1
      assert_equal( 1, vector1.assoc( "百合子" )[1] )
      vector2 = Document.new( corpus[3], :mecab, { :term_weight => :default } )
      #puts vector2
      assert(  vector2.assoc( "宮本" )[1] > vector2.assoc( "生活" )[1] )
      assert_not_equal( vector1.assoc( "宮本" )[1], vector2.assoc( "宮本" )[1] )
      vector3 = Document.new( corpus[3], :mecab, { :term_weight => :cost } )
      assert(  vector3.assoc( "宮本" )[1] > vector3.assoc( "生活" )[1] )
      assert(  vector3.assoc( "宮本" )[1] > vector2.assoc( "宮本" )[1] )

      # term_weight_position parameter:
      vector1 = Document.new( corpus[0], :mecab,
                              { :term_weight => :tf,
                                :term_weight_position => true } )
      assert_not_equal( 1, vector1.assoc( "百合子" )[1] )
      vector2 = Document.new( corpus[3], :mecab,
                              { :term_weight => :default,
                                :term_weight_position => true } )
      #puts vector2
      assert(  vector2.assoc( "宮本" )[1] < vector2.assoc( "自分" )[1] )
      assert_not_equal( vector1.assoc( "宮本" )[1], vector2.assoc( "宮本" )[1] )
      vector3 = Document.new( corpus[3], :mecab,
                              { :term_weight => :cost,
                                :term_weight_position => true } )
      assert(  vector3.assoc( "宮本" )[1] > vector3.assoc( "生活" )[1] )
      assert(  vector3.assoc( "宮本" )[1] > vector2.assoc( "宮本" )[1] )
   end
end
