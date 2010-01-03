#!/usr/local/bin/ruby
# -*- coding: euc-jp -*-
# $Id$

require "net/http"
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
      #puts lines
      lines = lines.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK|形容詞/ and l[1] !~ /接[頭尾]|非自立/ }
      #pp lines
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
      count = Hash.new( 0 )
      lines.each_with_index do |line, idx|
         next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/ # ASCII symbol chars
         next if line[0].size < 3
         #p line[2]
         #puts line
         #score = 1 / Math.log( line[2].to_i + 1 )
         score = Math.log10( line[2].to_i + 10 )
         #score = line[2].to_i
         #pp [ line[0], score, idx ]
         count[ line[0] ] += score #/ Math.log10( idx + 10 )
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
   url = cgi.referer || URI.escape( cgi.params["url"][0] )
   url = URI.parse( url )
   count = cgi.params["count"][0].to_i
   count = 5 if count < 1
   mode = cgi.params["mode"][0] || "mecab"
   http = Net::HTTP.new( url.host, url.port )
   http_response, = http.get( url.request_uri )
   content = http_response.body
   case http_response[ "content-type" ]
   when /^text\/html\b/
      content = content.toeuc
      content = ExtractContent::analyse( content ).join( "\n" )
      #puts content
   else
      raise "Unknown Content-Type: #{ http_response[ "content-type" ] }"
   end
   content = NKF.nkf( "-EeZ1", content ).downcase.strip
   #puts content.toutf8
   keywords = []
   case mode
   when "yahoo"
      keywords = extract_keywords_yahooapi( content )
   else
      keywords = extract_keywords_mecab( content )
   end
   #puts keywords
   data = nil
   keywords.dup.each do |k|
      if cinii_search( k.toutf8, { :format => "atom" } )[ :totalResults ] < 1
         keywords.shift
      else
         break
      end
   end
   TIMES = 10
   keyword = ""
   entries = []
   TIMES.times do |i|
      keyword = keywords[ 0..(TIMES-i-1) ].join( " " ).toutf8
      STDERR.puts keyword
      data = cinii_search( keyword, { :format => "atom" } )
      if data[ :totalResults ].to_i > 0
         if data[ :totalResults ].to_i < count
            entries += data[ :entries ]
            next
         else
            data[ :entries ] = ( entries + data[ :entries ] ).uniq
         end
         break
      end
   end
   data[ :count ] = count
   rhtml = open("../cinii.rhtml"){|io| io.read }
   include ERB::Util
   puts ERB::new( rhtml, $SAFE, 2 ).result( binding )
end
