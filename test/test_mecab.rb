#!/usr/bin/env ruby
# $Id$

require 'test/unit'

$:.push File.join( File.dirname( $0 ), ".." )
require "fuwatto.rb"

class TestMecab < Test::Unit::TestCase
   include Fuwatto
   def test_mecab
      res, = http_get( URI.parse("http://crd.ndl.go.jp/GENERAL/servlet/detail.reference?id=1000059361") )
      str = res.body.toeuc
      content = ExtractContent::analyse( str )
      assert( content.size > 0 )
      mecab = MeCab::Tagger.new
      content = mecab.parse( content.join )
      assert( content.size > 0 )
   end
end
