#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

$:.unshift( File.dirname( __FILE__ ) )
require "fuwatto.rb"

module Fuwatto
  class CiniiApp < BaseApp
    TERMS = 10
    TITLE = "ふわっとCiNii関連検索"
    HELP_TEXT = <<EOF
	<p>
	入力したテキストまたはウェブページに関連した論文を<a href="http://ci.nii.ac.jp">CiNii</a>で検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して論文検索できるのが特徴です。
	</p>
EOF
    def execute( method = :cinii_search, terms = TERMS, opts = {} )
      super( method, terms, opts )
    end
  end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   begin
      app = Fuwatto::CiniiApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true
	    opts[ :reranking ] = true
	 end
         data = app.execute( :cinii_search, Fuwatto::CiniiApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "cinii", data )
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
