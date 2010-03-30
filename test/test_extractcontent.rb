#!/usr/bin/env ruby
# $Id$

require 'test/unit'
require 'ftools'

$:.push File.join( File.dirname( $0 ), ".." )
require "fuwatto.rb"

class TestExtractContent < Test::Unit::TestCase
   include Fuwatto
   def test_extract_content
      res, = http_get( URI.parse("http://www.nims.go.jp/news/press/2010/03/p201003040.html") )
      str = res.body.toeuc
      content = ExtractContent::analyse( str )
      assert( content )
      assert_equal( content.size, 2 )
      assert( content[0] )
      assert_no_match( /&rdquo;/, content[0] )
   end
   def test_extract_content2
      res, = http_get( URI.parse("http://crd.ndl.go.jp/GENERAL/servlet/detail.reference?id=1000059361") )
      str = res.body.toeuc
      content = ExtractContent::analyse( str )
      STDERR.puts content.join.toeuc
      assert( content )
      assert( content.size > 0 )
   end
end
