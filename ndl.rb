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
      TITLE = "ふわっと NDL 関連検索"
      HELP_TEXT = <<EOF
<p>
入力したテキストまたはウェブページに関連した文献を<a href="http://porta.ndl.go.jp">NDL PORTA</a>で検索します。
長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して文献検索できるのが特徴です。
</p>
<p>
例:
<a href="?url=http://www.asahi.com/paper/editorial.html">朝日新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.asahi.com/paper/editorial.html">元記事(asahi.com)</a>）</span>, 
<a href="?url=http://www.nikkei.co.jp/news/shasetsu/">日本経済新聞社説</a> <span style="font-size:smaller;">（<a href="http://www.nikkei.co.jp/news/shasetsu/">元記事(nikkei.co.jp)</a>）</span>,
<a href="?url=http://mainichi.jp/select/opinion/eye/">毎日新聞「記者の目」</a> <span style="font-size:smaller;">（<a href="http://mainichi.jp/select/opinion/eye/">元記事(mainichi.jp)</a>）</span>
</p>
<p>
<a href="http://porta.ndl.go.jp">NDL Porta</a>において、国立国会図書館が提供している下記の12データベースを検索対象としています:<br/>
近代デジタルライブラリー,
貴重書サンプル,
貴重書画像データベース,
Dnavi,
NDL蔵書目録（和図書・和雑誌）,
NDL雑誌記事索引,
NDLプランゲ文庫雑誌・新聞目録,
レファレンス協同データベース,
カレントアウェアネス,
児童書デジタル・ライブラリー,
WARP,
国立国会図書館電子展示会
</p>
<p>
注意: 本サービスはデモ用のものです。検索対象が多いため、一回の検索あたり一分程度かかります。検索実行の際はしばらくお待ちください。
</p>
EOF
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
