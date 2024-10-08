#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   class JaWPApp < BaseApp
      TERMS = 5
      TITLE = "ふわっと ウィキペディア 関連検索"
      HELP_TEXT = <<-EOF
	<p>
	入力したテキストまたはウェブページに関連した記事を<a href="http://ja.wikipedia.org">日本語版ウィキペディア</a>で検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して検索できるのが特徴です。
	</p>
	<p>
	例:
	<a href="?url=http://www.asahi.com/paper/editorial.html">朝日新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.asahi.com/paper/editorial.html">元記事(asahi.com)</a>）</span>, 
	<a href="?url=http://mainichi.jp/select/opinion/eye/">毎日新聞「記者の目」</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/select/opinion/eye/">元記事(mainichi.jp)</a>）</span>
	</p>
      EOF
      def execute( method = :wikipedia_ja_search, terms = TERMS, opts = {} )
         super( method, terms, opts )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   begin
      app = Fuwatto::JaWPApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true 
	    opts[ :reranking ] = true 
	 end
	 #p opts
         data = app.execute( :wikipedia_ja_search, Fuwatto::JaWPApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "ja-wikipedia", data )
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
