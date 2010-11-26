#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   class EpiApp < BaseApp
      TERMS = 10
      TITLE = "ふわっと 教育研究論文索引 関連検索"
      HELP_TEXT = <<-EOF
<p>
入力したテキストまたはウェブページに関連した論文を<a href="http://www.nier.go.jp/library/">教育研究論文索引</a>で検索します。
長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して論文検索できるのが特徴です。
</p>
<p>
例:
<a href="?url=http://www.asahi.com/paper/editorial.html">朝日新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.asahi.com/paper/editorial.html">元記事(asahi.com)</a>）</span>,
<a href="?url=http://mainichi.jp/select/opinion/eye/">毎日新聞「記者の目」</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/select/opinion/eye/">元記事(mainichi.jp)</a>）</span>,
<a href="?url=http://mainichi.jp/life/edu/mori/">毎日新聞 教育の森</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/life/edu/mori/">元記事(mainichi.jp)</a>）</span>, 
</p>
      EOF
      def execute
         super( :epi_search, TERMS, { :maximumRecords => 20 } )
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
      app = Fuwatto::EpiApp.new( @cgi )
      data = {}
      begin
         data = app.execute
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "epi", data )
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
