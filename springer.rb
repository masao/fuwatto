#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   class SpringerApp < BaseApp
      TERMS = 10
      TITLE = "Fuwatto Springer Search / ふわっとSpringer関連検索"
      HELP_TEXT = <<-EOF
	<p style="text-align:center;padding:1ex;font-weight:bolder">
	Enjoy quick hack of <a href="http://dev.springer.com">Springer API</a> at Code4Lib JAPAN 2011 Camp!
	<br/>
	<small>Note: This service is just for demonstration purpose and it is very slow, 20sec. per search request.</small>
	</p>
	<p>
	入力したテキストまたはウェブページに関連した文献を<a href="http://springerlink.com">Springer社発行の学術論文・電子ブック</a>から検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して論文検索できるのが特徴です。
	</p>
	<p>
	例:
	<a href="?url=http://www.asahi.com/paper/editorial.html">朝日新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.asahi.com/paper/editorial.html">元記事(asahi.com)</a>）</span>, 
	<a href="?url=http://mainichi.jp/select/opinion/eye/">毎日新聞「記者の目」</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/select/opinion/eye/">元記事(mainichi.jp)</a>）</span>
	</p>
      EOF
      def execute( method = :springer_metadata_search, terms = TERMS, opts = {} )
         super( method, terms, opts )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   case @cgi.host
   when "kagaku.nims.go.jp"
      ENV[ 'http_proxy' ] = 'http://wwwout.nims.go.jp:8888'
   when "kaede.nier.go.jp"
      ENV[ 'http_proxy' ] = 'http://ifilter2.nier.go.jp:12080/'
   end
   begin
      app = Fuwatto::SpringerApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true 
	    opts[ :reranking ] = true 
	 end
         data = app.execute( :springer_metadata_search, Fuwatto::SpringerApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "springer", data )
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
