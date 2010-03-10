#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   class NDLApp < BaseApp
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
