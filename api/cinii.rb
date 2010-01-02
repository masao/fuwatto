#!/usr/local/bin/ruby
# -*- coding: euc-jp -*-
# $Id$

require "cgi"
require "kconv"
require "MeCab"
require "extractcontent"

require "../cinii.rb"

module Zubatto
   YAHOO_KEYWORD_BASEURI = "http://jlp.yahooapis.jp/KeyphraseService/V1/extract"
   YAHOO_APPID = "W11oHSWxg65mAdRwjBT4ylIdfS9PkHPjVvtJzx9Quwy.um8e1LPf_b.4usSBcmI-"
   def extract_keywords_yahooapi( str )
      #cont = open( "?appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str ) }&output=xml" ){|io| io.read }
      uri = URI.parse( YAHOO_KEYWORD_BASEURI )
      http = Net::HTTP.new( uri.host, uri.port )
      xml = nil
      http.start do |conn|
         data = "appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str.toutf8 ) }&output=xml"
         # p data
         res, = conn.post( uri.path, data )
         xml = res.body
      end
      #p xml
      parser = LibXML::XML::Parser.string( xml )
      doc = parser.parse
      keywords = doc.find( "//y:Keyphrase", "y:urn:yahoo:jp:jlp:KeyphraseService" ).map{|e| e.content.toeuc }
      #keywords.each do |e|
      #   p e.content
      #end
      keywords
   end
   def extract_keywords_mecab( str )
      mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
      lines = mecab.parse( str )
      lines = lines.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK/ and l[1] !~ /接[頭尾]/ }
      #pp lines
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
      count = Hash.new( 0 )
      lines.each_with_index do |line, idx|
         #next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]\Z/ # ASCII symbol chars
         next if line[0].size < 3
         #p line[2]
         #puts line
         #score = 1 / Math.log( line[2] + 1 )
         score = Math.log( line[2].to_i + 1 )
         #pp [ line[0], score, idx ]
         count[ line[0] ] += score / Math.log10( idx + 10 )
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
   cgi = CGI.new
   puts "Content-Type: text/html\n\n"
   url = cgi.referer || cgi.params["url"][0]
   content = open( url ){|io| io.read }
   content = content.toeuc
   content = ExtractContent::analyse( content )[0]
   #content = content.toeuc
   #puts content
   keywords = []
   mode = cgi.params["mode"][0] || "mecab"
   case mode
   when "yahoo"
      keywords = extract_keywords_yahooapi( content )
   else
      keywords = extract_keywords_mecab( content )
   end
   #puts keywords
   data = nil
   TIMES = 10
   keywords.dup.each do |k|
      if cinii_search( k.toutf8, { :format => "atom" } )[ :totalResults ] < 1
         keywords.shift
      else
         break
      end
   end
   TIMES.times do |i|
      keyword = keywords[ 0..(TIMES-i-1) ].join( " " ).toutf8
      data = cinii_search( keyword, { :format => "atom" } )
      break if data[ :totalResults ].to_i > 0
   end
   rhtml = open("../cinii.rhtml"){|io| io.read }
   include ERB::Util
   puts ERB::new( rhtml, $SAFE, 2 ).result( binding )
end
