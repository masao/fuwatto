#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "fuwatto.rb"
require_relative "cinii.rb"

module Fuwatto
   class CiniiAuthorApp < CiniiApp
      TERMS = 10
      TITLE = "ふわっとCiNii関連著者検索"
      HELP_TEXT = <<-EOF
	<p>
	入力したテキストまたはウェブページに関連する論文著者を<a href="http://ci.nii.ac.jp">CiNii</a>から検索します。
	長いテキストやURLで指定したページからでも関連キーワードを自動的に抜き出して関連する人物（研究者）を検索できるのが特徴です。
	</p>
      EOF
      def execute( method = :cinii_author_search, terms = TERMS, opts = {} )
         opts[ :reranking ] = true
         opts[ :combination ] = true
         data = super( :cinii_search, terms, opts )
         return data if data.empty?
         authors = {}
         data[ :entries ].each_with_index do |entry, i|
            score = entry[ :score ]
            # score = i if score.nil?
            author_list = entry[ :author ].split( /; / )
            author_list.each_with_index do |a, order|
               authors[ a ] ||= { :score => 0, :entry => [] }
               # authors[ a ] += score / Math.log2( order + 2 )
               if order == 0
                  authors[ a ][ :score ] += score
               else
                  authors[ a ][ :score ] += score / Math.log2( author_list.size + 1 )
               end
               authors[ a ][ :entry ] << entry
            end
            break if authors.size > 500
         end
         entries = []
         authors.keys.sort_by{|e| authors[ e ][ :score ] }.reverse.each do |a|
            # p authors[ a ][ :entry ]
            entries << {
               :author => a,
               :url => "http://ci.nii.ac.jp/opensearch/search?author=%2f#{ CGI.escape( a.gsub( /\s*,\s*/, " " ) ) }%2f",
               :score => authors[ a ][ :score ],
               :articles => authors[ a ][ :entry ],
            }
         end
         data[ :entries ] = entries
         data
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   @cgi = CGI.new
   begin
      app = Fuwatto::CiniiAuthorApp.new( @cgi )
      data = {}
      begin
         opts = {}
	 if not @cgi[ "combination" ].empty?
	    opts[ :combination ] = true 
	    opts[ :reranking ] = true 
	    opts[ :prf ] = true
	 end
         data = app.execute( :cinii_author_search, Fuwatto::CiniiAuthorApp::TERMS, opts )
      rescue Fuwatto::NoHitError => e
         data[ :error ] = e.class
      end
      app.output( "cinii_author", data )
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
