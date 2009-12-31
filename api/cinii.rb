#!/usr/local/bin/ruby
# -*- coding: euc-jp -*-
# $Id$

require "kconv"
require "extractcontent"

require "../cinii.rb"

module Zubatto
   def extract_keywords_mecab( str )
      require "MeCab"
      mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
      lines = mecab.parse( str )
      lines = lines.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK/ }
      #pp lines
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] }
      count = Hash.new( 0 )
      lines.each_with_index do |line, idx|
         next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]\Z/ # ASCII symbol chars
         #p line[2].to_i
         #puts line
         score = 1 / Math.log( line[2] + 1 )
         #pp [ line[0], score, idx ]
         count[ line[0] ] += score / Math.log( idx + 2 )
      end
      #pp count
      ranks = count.keys.sort_by{|e| count[e] }.reverse
      #pp ranks
      #3.times do |i|
      #   puts [ i+1, ranks[i], count[ ranks[i] ] ].join( "\t" )
      #end
   end
end

if $0 == __FILE__
   include Zubatto
   puts "Content-Type: text/html\n\n"
   url = ENV['HTTP_REFERER']
   content = open( url ){|io| io.read }
   content = content.toeuc
   content = ExtractContent::analyse( content )[0]
   #content = content.toeuc
   #puts content
   keywords = extract_keywords_mecab( content )
   data = nil
   5.times do |i|
      keyword = keywords[ 0..(5-i) ].join( " " ).toutf8
      data = cinii_search( keyword, { :format => "atom" } )
      break if data[ :totalResults ].to_i > 0
   end
   rhtml = open("../cinii.rhtml"){|io| io.read }
   include ERB::Util
   puts ERB::new( rhtml, $SAFE, 2 ).result( binding )
end
