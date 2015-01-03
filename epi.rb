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
      EOF
      def execute
         super( :epi_search, TERMS, { :maximumRecords => 20 } )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
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
