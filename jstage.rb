#!/usr/bin/env ruby
# -*- coding: euc-jp -*-
# $Id$

require "fuwatto.rb"

module Fuwatto
   class JStageApp < BaseApp
      TERMS = 10
      TITLE = "�դ�ä�J-Stage��Ϣ����"
      HELP_TEXT = <<-EOF
	<p>
	���Ϥ����ƥ����Ȥޤ��ϥ����֥ڡ����˴�Ϣ������ʸ��<a href="http://www.jstage.jst.go.jp/browse/-char/ja">J-STAGE</a>�Ǹ������ޤ���
	Ĺ���ƥ����Ȥ�URL�ǻ��ꤷ���ڡ�������Ǥ��Ϣ������ɤ�ưŪ��ȴ���Ф�����ʸ�����Ǥ���Τ���ħ�Ǥ���
	</p>
	<p>
	��:
	<a href="?url=http://www.asahi.com/paper/editorial.html">ī����ʹ����</a> <span style="font-size:smaller;">��<a href="http://www.asahi.com/paper/editorial.html">������(asahi.com)</a>��</span>, 
	<a href="?url=http://mainichi.jp/select/opinion/eye/">������ʹ�ֵ��Ԥ��ܡ�</a> <span style="font-size:smaller;">��<a href="http://mainichi.jp/select/opinion/eye/">������(mainichi.jp)</a>��</span>
	</p>
      EOF
      def execute( method = :jstage_search, terms = TERMS, opts = {} )
         super( method, terms, opts )
      end
   end
end

if $0 == __FILE__
   # �����˻��Ѥ�����祭����ɿ�
   @cgi = CGI.new
   case @cgi.host
   when "kagaku.nims.go.jp"
      ENV[ 'http_proxy' ] = 'http://wwwout.nims.go.jp:8888'
   when "fuwat.to", "kaede.nier.go.jp"
      ENV[ 'http_proxy' ] = 'http://ifilter2.nier.go.jp:12080/'
   end
   begin
      app = Fuwatto::JStageApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true 
	    opts[ :reranking ] = true 
	    opts[ :prf ] = true
	 end
         data = app.execute( :jstage_search, Fuwatto::JStageApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "jstage", data )
      STDERR.puts "$http_count: #{ $http_count }"
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
