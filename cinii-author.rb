#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"
require "cinii.rb"

module Fuwatto
   class CiniiAuthorApp < CiniiApp
      TERMS = 10
      TITLE = "ふわっとCiNii関連著者検索"
      HELP_TEXT = <<-EOF
	<p>
	入力したテキストまたはウェブページに関連した論文著者を<a href="http://ci.nii.ac.jp">CiNii</a>から検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して関連する人物を検索できるのが特徴です。
	</p>
	<p>
	例:
	<a href="?url=http://www.asahi.com/paper/editorial.html">朝日新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.asahi.com/paper/editorial.html">元記事(asahi.com)</a>）</span>, 
	<a href="?url=http://mainichi.jp/select/opinion/eye/">毎日新聞「記者の目」</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/select/opinion/eye/">元記事(mainichi.jp)</a>）</span>
	</p>
      EOF
      def execute( method = :cinii_author_search, terms = TERMS, opts = {} )
         opts[ :reranking ] = true
         data = super( :cinii_search, terms, opts )
         return data if data.empty?
         authors = {}
         data[ :entries ].each_with_index do |entry, i|
            score = entry[ :score ]
            # score = i if score.nil?
            entry[ :author ].split( /; / ).each do |a|
               authors[ a ] ||= 0
               authors[ a ] += score
            end
         end
         entries = []
         authors.keys.sort_by{|e| authors[ e ] }.reverse.each do |a|
            entries << {
               :author => a,
               :url => "http://ci.nii.ac.jp/opensearch/search?author=#{ CGI.escape( a ) }",
               :score => authors[ a ]
            }
         end
         data[ :entries ] = entries
         data
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
      app = Fuwatto::CiniiAuthorApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true 
	    opts[ :reranking ] = true 
	    opts[ :prf ] = true
	 end
         data = app.execute( :cinii_author_search, Fuwatto::CiniiAuthorApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "cinii_author", data )
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
