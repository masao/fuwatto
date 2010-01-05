#!/usr/local/bin/ruby
# -*- coding: euc-jp -*-
# $Id$

require "net/http"
require "cgi"
require "kconv"
require "MeCab"
require "extractcontent"

require "../cinii.rb"

if $0 == __FILE__
   TIMES = 10
   include Fuwatto
   @cgi = CGI.new
   begin
      url = @cgi.referer || @cgi.params["url"][0]
      if url.nil?
         raise "empty URL"
      end
      url = URI.parse( url )
      count = @cgi.params["count"][0].to_i
      count = 5 if count < 1
      mode = @cgi.params["mode"][0] || "mecab"
      response = http_get( url )
      content = response.body
      case response[ "content-type" ]
      when /^text\/html\b/
         content = content.toeuc
         content = ExtractContent::analyse( content ).join( "\n" )
         #puts content
      when /^text\/plain/
         content = content.toeuc
      else
         raise "Unknown Content-Type: #{ response[ "content-type" ] }"
      end
      vector = Document.new( content )
      data = nil
      vector[0, TIMES].dup.each do |k|
         if cinii_search( k.toutf8 )[ :totalResults ] < 1
            vector.delete( k )
         end
      end
      keyword = ""
      entries = []
      TIMES.times do |i|
         keyword = vector[ 0..(TIMES-i-1) ].join( " " ).toutf8
         STDERR.puts keyword
         data = cinii_search( keyword )
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
      print @cgi.header
      rhtml = open("../cinii.rhtml"){|io| io.read }
      include ERB::Util
      puts ERB::new( rhtml, $SAFE, "<>" ).result( binding )
   rescue Exception
      if @cgi then
         print @cgi.header( 'status' => CGI::HTTP_STATUS['SERVER_ERROR'], 'type' => 'text/html' )
      else
         print "Status: 500 Internal Server Error\n"
         print "Content-Type: text/html\n\n"
      end
      puts "<h1>500 Internal Server Error</h1>"
      puts "<pre>"
      puts CGI::escapeHTML( "#{$!} (#{$!.class})" )
      puts ""
      puts CGI::escapeHTML( $@.join( "\n" ) )
      puts "</pre>"
      puts "<div>#{' ' * 500}</div>"
   end
end
