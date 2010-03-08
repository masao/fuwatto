#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   DPID_LABEL = {
      "kindai" => "近デジ",
      "rarebook" => "NDL貴重書",
      "rarebook-sample" => "貴重書サンプル",
      "jido-dl" => "児童書DL",
      "webcont" => "NDL電展",
      "zomoku" => "NDL和図書/雑誌",
      "prange" => "プランゲ文庫",
      "zassaku" => "雑誌記事索引",
      "jido-somoku" => "児童書総目",
      "dnavi" => "Dnavi",
      "warp" => "WARP",
      "refkyo" => "レファ協",
      "awareness" => "カレント",
   }
   def ndl_search( keyword, opts = {} )
      base_uri = "http://api.porta.ndl.go.jp/servicedp/opensearch"
      q = URI.escape( keyword )
      # TODO: Atom/RSSの双方を対象にできるようにすること（現状は Atom のみ）
      opts[ :format ] = "atom"
      opts[ :dpgroupid ] = "ndl"
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e].to_s ) }"
         end.join( "&" )
      end
      cont = nil
      opensearch_url = "#{ base_uri }?any=#{ q }&#{ opts_s }"
      open( opensearch_url ) do |res|
         cont = res.read
      end
      #open( "result.xml", "w" ){|io| io.puts cont }
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      #p cont
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      #puts keyword.toeuc
      data[ :q ] = keyword
      data[ :link ] = "http://porta.ndl.go.jp/cgi-bin/openurl.cgi"
      data[ :totalResults ] = doc.find( "//openSearch:totalResults", "http://a9.com/-/spec/opensearchrss/1.0/" )[0].content.to_i
      entries = doc.find( "//item" )
      data[ :entries ] = []
      entries.each do |e|
         dpid = e.find( "./dcndl_porta:dpid", "http://ndl.go.jp/dcndl/dcndl_porta/" )[0].content
         title = e.find( "./title" )[0].content
         #puts title.toeuc
         url = e.find( "./link" )[0].content
         author = e.find( ".//author" )
         if author and author[0]
            author = author[0].content
         else
            author = ""
         end
         source = e.find( "./source" )
         if source and source[0]
            source = source[0].content
         else
            source = ""
         end
         publicationName = e.find( "dcterms:bibliographicCitation", "http://purl.org/dc/terms/" )
         if publicationName and publicationName[0]
            publicationName = publicationName[0].content
         else
            publicationName = nil
         end
         date = e.find( "./dcterms:issued", "http://purl.org/dc/terms/" )
         if date and date[0]
            date = date[0].content
         else
            date = e.find( "./dcterms:modified", "http://purl.org/dc/terms/" )
            if date and date[0]
               date = date[0].content
            else
               date = nil
            end
         end
         publisher = e.find( "./dc:publisher", "http://purl.org/dc/elements/1.1/" )
         if publisher and publisher[0]
            publisher = publisher[0].content
         else
            publisher = nil
         end
         description = e.find( "./description" )
         if description and description[0] and dpid != "zassaku"
            description = description[0].content
         else
            description = ""
         end
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :source => source,
            :date => date,
            :publisher => publisher,
            :publicationName => publicationName,
            :description => description,
            :dpid => dpid,
         }
      end
      data
   end
   class NDLApp < BaseApp
      TERMS = 5
      def execute
         super( :ndl_search, TERMS )
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
      app = Fuwatto::NDLApp.new( @cgi )
      data = app.execute
      app.output( "ndl", data )
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