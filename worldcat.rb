#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   WORLDCAT_BASIC_WSKEY = "5lIR8i5bSQQNg4Xb3ro6QbOzXiGSs6PrGGJ02BKolP9qTUQRcui2Ze9AsQIlM8IzV0E9XMcrWWieWvrM"
   def worldcat_search( keyword, opts = {} )
      base_uri = "http://worldcat.org/webservices/catalog/search/opensearch"
      q = URI.escape( keyword )
      # TODO: Atom/RSSの双方を対象にできるようにすること（現状は Atom のみ）
      opts[ :format ] = "atom"
      opts[ :wskey ] = WORLDCAT_BASIC_WSKEY
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e].to_s ) }"
         end.join( "&" )
      end
      cont = nil
      opensearch_url = "#{ base_uri }?q=#{ q }&#{ opts_s }"
      open( opensearch_url ) do |res|
         cont = res.read
      end
      #open( "result.xml", "w" ){|io| io.puts cont }
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      #puts keyword.toeuc
      data[ :q ] = keyword
      # data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" ).sub( /&wskey=\w+/, "" )
      data[ :link ] = "http://www.worldcat.org/search?q=#{ q }"
      data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content.to_i
      entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
         #puts title.toeuc
         url = e.find( "./atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content
         author = e.find( ".//atom:author/atom:name", "atom:http://www.w3.org/2005/Atom" ).to_a.map{|name| name.content }.join( "; " )
         content = e.find( "./atom:content", "atom:http://www.w3.org/2005/Atom" )[0]
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :content => content,
         }
      end
      data
   end
   class WorldcatApp < BaseApp
      TERMS = 5
      def execute
         super( :worldcat_search, TERMS )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   case @cgi.host
   when "kagaku.nims.go.jp"
      ENV[ 'http_proxy' ] = 'http://wwwout.nims.go.jp:8888'
   when "fuwat.to", "kaede.nier.go.jp"
      ENV[ 'http_proxy' ] = 'http://ifilter2.nier.go.jp:12080/'
   end
   begin
      app = Fuwatto::WorldcatApp.new( @cgi )
      data = app.execute
      app.output( "worldcat", data )
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
