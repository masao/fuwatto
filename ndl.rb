#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "fuwatto.rb"

module Fuwatto
   class NDLApp < BaseApp
      DPID_TARGETS = {
        :zassaku => "NDL雑誌記事索引",
	:refkyo  => "レファレンス協同データベース",
	:awareness => "カレントアウェアネス",
	:webcont => "国立国会図書館電子展示会",
	:research => "リサーチナビ",
	:"iss-yunika" => "総合目録ネットワーク（ゆにかねっと）",
	:"iss-ndl-opac" => "NDL-OPAC",
	:"iss-shinbun" => "新聞総合目録",
	:"iss-jido-somoku" => "児童書総合目録",
	:"ndl-dl" => "国立国会図書館デジタルコレクション",
	:"ndl-dl-online" => "国立国会図書館デジタルコレクション（電子書籍・電子雑誌）",
	:tenroku => "点字図書・録音図書全国総合目録",
	:"ndl-dl-daisy" => "国立国会図書館DAISY資料",
	:aozora => "青空文庫",
      }
      TERMS = 5
      TITLE = "ふわっと NDL 関連検索"
      HELP_TEXT = <<EOF
<p>
入力したテキストまたはウェブページに関連した文献を<a href="http://iss.ndl.go.jp">NDLサーチ</a>で検索します。
長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して文献検索できるのが特徴です。
</p>
<p>
<a href="http://iss.ndl.go.jp">NDLサーチ</a>において、国立国会図書館が提供している下記の#{ DPID_TARGETS.size }データベースを検索対象としています:
<div style="font-size:smaller;margin: 0pt 4em;">
#{ DPID_TARGETS.values.join( ", " ) }
</div>
</p>
<p>
注意: 本サービスはデモ用のものです。検索対象が多いため、一回の検索あたり一分程度かかります。検索実行の際はしばらくお待ちください。
</p>
EOF
      def execute
         super( :iss_ndl_search, TERMS )
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
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
