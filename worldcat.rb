#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "fuwatto.rb"

module Fuwatto
   class WorldcatApp < BaseApp
      TERMS = 5
      TITLE = "ふわっとWorldCat関連検索 / Fuwatto WorldCat Search"
      HELP_TEXT = <<-EOF
<p>
This search tool allows you to search <a href="http://www.worldcat.org">WorldCat</a> just by specifying free text or a web page. The tool automatically extracts feature words from the specified contents, and returns a ranked list of bibliographic information ordered by relevance score.
</p>
<p>
入力したテキストまたはウェブページに関連した文献を<a href="http://www.worldcat.org">WorldCat</a>で検索します。
長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して文献検索できるのが特徴です。
</p>
<p style="text-align:center;padding:1ex;font-weight:bolder">
Enjoy my quick hack of WorldCat Basic API at Code4Lib 2010 Conference!<br/>
(from <a href="http://worldcat.org/devnet/wiki/C4l10">OCLC Web Services and Lightning Talk Demos</a> session)
<br/>
<small>Note: This service is just for demonstration purpose and it is very slow, 20sec. per search request.</small>
</p>
EOF
     EXAMPLE_TEXT = <<EOF
<div id="feed"></div>
EOF
      def execute
         super( :worldcat_search, TERMS, { :count => count } )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
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
