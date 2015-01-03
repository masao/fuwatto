#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "fuwatto.rb"

module Fuwatto
   class SpringerApp < BaseApp
      TERMS = 10
      TITLE = "Fuwatto Springer Search / ふわっとSpringer関連検索"
      HELP_TEXT = <<-EOF
	<p>
	This search tool allows you to search <a href="http://springerlink.com">Springer Link</a> just by specifying free text or a web page. The tool automatically extracts feature words from the specified contents, and returns a ranked list of bibliographic information ordered by relevance score.
	</p>
	<p style="text-align:center;padding:1ex;font-weight:bolder">
	Enjoy quick hack of <a href="http://dev.springer.com">Springer API</a> at Code4Lib JAPAN 2011 Camp!
	<br/>
	<small>Note: This service is just for demonstration purpose and it is very slow, 20sec. per search request.</small>
	</p>
	<p>
	入力したテキストまたはウェブページに関連した文献を<a href="http://springerlink.com">Springer社発行の学術論文・電子ブック</a>から検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して論文検索できるのが特徴です。
	</p>
EOF
     EXAMPLE_TEXT = <<EOF
	<div id="feed"></div>
EOF
      def execute( method = :springer_metadata_search, terms = TERMS, opts = {} )
         super( method, terms, opts )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
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
