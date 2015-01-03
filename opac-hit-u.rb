#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "fuwatto.rb"

module Fuwatto
   class OPACHitUApp < BaseApp
      TERMS = 5
      TITLE = "ふわっと 一橋大学OPAC 関連検索"
      HELP_TEXT = <<EOF
<p>
入力したテキストまたはウェブページに関連した論文を<a href="http://opac.lib.hit-u.ac.jp">一橋大学OPAC</a>で検索します。
長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して文献検索できるのが特徴です。
</p>
EOF
      def execute
         super( :opac_hit_u_search, TERMS )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   begin
      app = Fuwatto::OPACHitUApp.new( @cgi )
      data = app.execute
      app.output( "opac_hit_u", data )
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
