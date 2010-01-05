#!/usr/local/bin/ruby
# -*- coding: euc-jp -*-
# $Id$

require "open-uri"
require "net/http"
#require "pp"
require "erb"
require "cgi"
require "nkf"
require "kconv"
require "rubygems"
require "libxml"
require "MeCab"
require "extractcontent"

module Fuwatto
   def cinii_search( keyword, opts = {} )
      base_uri = "http://ci.nii.ac.jp/opensearch/search"
      q = URI.escape( keyword )
      # TODO: Atom/RSSの双方を対象にできるようにすること（現状は Atom のみ）
      opts[ :format ] = "atom"
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e] ) }"
         end.join( "&" )
      end
      cont = nil
      opensearch_url = "#{ base_uri }?q=#{ q }&#{ opts_s }"
      open( opensearch_url ) do |res|
         cont = res.read
      end
      #open( "result.xml", "w" ){|io| io.puts cont }

      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      #puts keyword.toeuc
      data[ :q ] = keyword
      data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" )
      data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content.to_i
      entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
         #puts title.toeuc
         url = e.find( "./atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content
         author = e.find( ".//atom:author/atom:name", "atom:http://www.w3.org/2005/Atom" ).to_a.map{|name| name.content }.join( "; " )
         pubname = e.find( "./prism:publicationName", "prism:http://prismstandard.org/namespaces/basic/2.0/" )[0]
         if pubname.nil?
            pubname = e.find( "./dc:publisher", "dc:http://purl.org/dc/elements/1.1/" )[0]
            pubname = pubname.content if pubname
         else
            pubname = pubname.content
         end
         pubdate = e.find( "./prism:publicationDate", "prism:http://prismstandard.org/namespaces/basic/2.0/" )[0] #.content
         pubdate = pubdate.nil? ? "" : pubdate.content
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :publicationName => pubname,
            :publicationDate => pubdate,
         }
      end
      data
   end

   YAHOO_KEYWORD_BASEURI = "http://jlp.yahooapis.jp/KeyphraseService/V1/extract"
   YAHOO_APPID = "W11oHSWxg65mAdRwjBT4ylIdfS9PkHPjVvtJzx9Quwy.um8e1LPf_b.4usSBcmI-"
   def extract_keywords_yahooapi( str )
      #cont = open( "?appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str ) }&output=xml" ){|io| io.read }
      uri = URI.parse( YAHOO_KEYWORD_BASEURI )
      http = Net::HTTP.new( uri.host, uri.port )
      xml = nil
      http.start do |conn|
         data = "appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str.toutf8 ) }&output=xml"
         # p data
         res, = conn.post( uri.path, data )
         xml = res.body
      end
      #p xml
      parser = LibXML::XML::Parser.string( xml )
      doc = parser.parse
      keywords = doc.find( "//y:Keyphrase", "y:urn:yahoo:jp:jlp:KeyphraseService" ).map{|e| e.content.toeuc }
      #keywords.each do |e|
      #   p e.content
      #end
      keywords.select{|e| not e.nil? and not e.empty? }
   end
   def extract_keywords_mecab( str )
      mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
      lines = mecab.parse( str )
      #puts lines
      lines = lines.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK|形容詞/ and l[1] !~ /接[頭尾]|非自立|代名詞/ }
      #pp lines
      raise "Extracting keywords from a text failed." if lines.empty?
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
      count = Hash.new( 0 )
      lines.each_with_index do |line, idx|
         next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/o # ASCII symbol chars
         next if line[0] =~ /\A(?:w(?:h(?:e(?:re(?:a(?:[st]|fter)|u(?:nto|pon)|in(?:to)?|o[fn]?|from|with|ver|by)?|n(?:(?:so)?ever|ce)?|ther)|o(?:m(?:(?:so)?ever)?|s(?:oever|e)|ever|le)?|i(?:ch(?:(?:so)?ever)?|l(?:st|e)|ther)|at(?:(?:so)?ever)?|y)|i(?:th(?:out|in)?|ll)|e(?:ll|re)?|ould|as)|a(?:l(?:(?:bei|mos)t|on[eg]|though|ready|ways|so|l)|n(?:y(?:(?:wher|on)e|thing|how)?|other|d)?|fter(?:wards)?|bo(?:ut|ve)|gain(?:st)?|mong(?:st)?|r(?:ound|e)|(?:cros)?s|dj|t)?|t(?:h(?:e(?:re(?:(?:upo|i)n|afte|for|by)?|m(?:selves)?|n(?:ce)?|ir|se|y)?|r(?:ough(?:out)?|u)|o(?:ugh|se)|[iu]s|a[nt])|o(?:gether|wards?|o)?)?|s(?:o(?:me(?:t(?:imes?|hing)|(?:wher|on)e|how)?)?|e(?:em(?:ing|ed|s)?|veral)|(?:inc|am)e|h(?:ould|e)|till|uch)?|b(?:e(?:c(?:om(?:es?|ing)|a(?:us|m)e)|fore(?:hand)?|(?:hi|yo)nd|(?:twe)?en|sides?|ing|low)?|oth|ut|y)|h(?:e(?:r(?:e(?:(?:upo|i)n|by)?|s(?:elf)?)?|eafter|nce)?|i(?:m(?:self)?|s)|a(?:[ds]|ve)|ow(?:ever)?)|o(?:u(?:r(?:(?:selve)?s)?|t)|n(?:ce one|ly|to)?|ther(?:wise|s)?|f(?:ten|f)?|(?:ve)?r|wn)|e(?:ve(?:r(?:y(?:(?:wher|on)e|thing)?)?|n)|ls(?:ewher)?e|(?:noug|ac)h|ither|xcept|tc|g)|n(?:o(?:[rw]|t(?:hing)?|body|o?ne)?|e(?:ver(?:theless)?|ither|xt)|amely|where)|m(?:o(?:re(?:over)?|st(?:ly)?)|(?:eanwhil)?e|u(?:ch|st)|y(?:self)?|an?y|ight)|i(?:[efs]|n(?:deed|to|c)?|t(?:s(?:elf)?)?)?|f(?:or(?:mer(?:ly)?)?|urther|irst|rom|ew)|l(?:a(?:tter(?:ly)?|st)|e(?:ast|ss)|td)|y(?:ou(?:r(?:s(?:el(?:ves|f))?)?)?|et)|x(?:author|other |note|subj|cal)|u(?:n(?:der|til)|p(?:on)?|s)|c(?:an(?:not)?|o(?:uld)?)|d(?:uring|own)|per(?:haps)?|v(?:ery|ia)|rather)\Z/o
         #next if line[0].size < 3
         #p line[2]
         #puts line.join("\t")
         #score = 1 / Math.log( line[2].to_i + 1 )
         score = Math.log10( line[2].to_i + 10 )
         #score = line[2].to_i
         #pp [ line[0], score, idx ]
         count[ line[0] ] += score #/ Math.log10( idx + 10 )
      end
      #pp count
      ranks = count.keys.sort_by{|e| count[e] }.reverse
      #pp ranks
      #3.times do |i|
      #   puts [ i+1, ranks[i], count[ ranks[i] ] ].join( "\t" )
      #end
      ranks
   end
   # Supports redirect
   def http_get( uri, limit = 3 )
      raise "Too many redirects: #{ uri }" if limit < 0
      http = Net::HTTP.new( uri.host, uri.port )
      response, = http.get( uri.request_uri )
      #if response.code !~ /^2/
      #   response.each do |k,v|
      #      p [ k, v ]
      #   end
      #end
      case response
      when Net::HTTPSuccess
         response
      when Net::HTTPRedirection
         uri = URI.parse( response['Location'] )
         STDERR.puts "redirect to #{ uri } (#{limit})"
         http_get( uri, limit - 1 )
      else
         response.error!
      end
   end

   # Bag of Words による文書表現
   class Document < Array
      attr_reader :content
      def initialize( content, mode = "default" )
         super()
         @content = NKF.nkf( "-em0XZ1", content ).gsub( /\s+/, " " ).strip
         normalized_content = @content.downcase.strip
         clear
         case mode
         when "yahoo"
            self.push( *extract_keywords_yahooapi( normalized_content ) )
         else
            self.push( *extract_keywords_mecab( normalized_content ) )
         end
         #puts self
      end
   end
end

if $0 == __FILE__
   # 検索に使用する最大キーワード数
   TERMS = 10
   include Fuwatto
   include ERB::Util
   @cgi = CGI.new
   time_pre = Time.new
   begin
      url = @cgi.params["url"][0]
      content = @cgi.params["text"][0]
      if url.nil? and content.nil?
      else
         if url
            url = URI.parse( url ) 
            response = http_get( url )
            content = response.body
            case response[ "content-type" ]
            when /^text\/html\b/
               content = content.toeuc
               content = ExtractContent::analyse( content ).join( "\n" )
               #puts content
            when /^text\/plain/
               content = content.toeuc
            else
               raise "Unknown Content-Type: #{ response[ "content-type" ] }"
            end
         end
         count = @cgi.params["count"][0].to_i
         count = 5 if count < 1
         mode = @cgi.params["mode"][0] || "mecab"
         vector = Document.new( content )
         data = nil
         vector[0, TERMS].dup.each do |k|
            if cinii_search( k.toutf8 )[ :totalResults ] < 1
               vector.delete( k )
            end
         end
         keyword = ""
         entries = []
         total_count = 0
         TERMS.times do |i|
            keyword = vector[ 0..(TERMS-i-1) ].join( " " ).toutf8
            STDERR.puts keyword
            data = cinii_search( keyword )
            if data[ :totalResults ].to_i > 0
               total_count += data[ :totalResults ]
               if total_count <= count
                  entries += data[ :entries ]
                  next
               else
                  data[ :entries ] = ( entries + data[ :entries ] ).uniq
               end
               break
            end
         end
         data[ :totalCount ] = total_count
         data[ :count ] = count
         data[ :searchTime ] = "%0.02f" % ( Time.now - time_pre )
         rhtml = open( "./cinii.rhtml" ){|io| io.read }
         cinii_result = ERB::new( rhtml, $SAFE, "<>" ).result( binding )
      end
      print @cgi.header
      rhtml = open("./cinii_top.rhtml"){|io| io.read }
      puts ERB::new( rhtml, $SAFE, "<>" ).result( binding )
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
