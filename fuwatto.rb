#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "net/http"
require "net/https"
#require "pp"
require "digest/md5"
require "tempfile"
require "erb"
require "cgi"
require "nkf"
require "kconv"

require "rubygems"
require "json"
require "libxml"
begin
   require "MeCab"
rescue LoadError
   require "mecab_local.rb"
end
begin
   require "extractcontent"
rescue LoadError
   #   require "extractcontent_local.rb"
end

module Math
   def self::log2( n )
      Math.log10( n ) / Math.log10( 2 )
   end
end

class String
   def shorten( len = 120 )
      matched = self.gsub( /\n/, ' ' ).scan( /^.{0,#{len - 2}}/u )[0]
      if $'.nil? || $'.empty?
         matched
      else
         matched + '..'
      end
   end
end

module Fuwatto
   VERSION = '1.0.3'
   BASE_URI = 'http://fuwat.to/'
   USER_AGENT = "Fuwatto Search/#{ VERSION }; #{ BASE_URI }"
   CACHE_TIME = 60 * 60 * 24 * 3   # 3日経つまで、キャッシュは有効
   MAX_PAGE = 19 # ページネイションに表示されるアイテム数

   # Bag of Words による文書表現
   class Document < Array
      include Fuwatto
      attr_reader :content
      def initialize( content, mode = "mecab" )
         super()
         return if content.nil?
         @content = NKF.nkf( "-wm0XZ1", content ).gsub( /\s+/, " " ).strip
         normalized_content = @content.downcase
         clear
         case mode
         when "yahoo"
            self.push( *extract_keywords_yahooapi( normalized_content ) )
         else
            self.push( *extract_keywords_mecab( normalized_content ) )
         end
         #puts self
      end
      # 類似度計算
      def sim( vector )
         sum = 0
         vector.each do |k, v|
            term = self.assoc( k )
            sum += v * term[1] if term
         end
         sum / vector.size
      end
   end

   YAHOO_KEYWORD_BASEURI = "http://jlp.yahooapis.jp/KeyphraseService/V1/extract"
   YAHOO_APPID = "W11oHSWxg65mAdRwjBT4ylIdfS9PkHPjVvtJzx9Quwy.um8e1LPf_b.4usSBcmI-"
   def extract_keywords_yahooapi( str )
      #cont = open( "?appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str ) }&output=xml" ){|io| io.read }
      uri = URI.parse( YAHOO_KEYWORD_BASEURI )
      #response = http_get( uri )
      http = Net::HTTP.new( uri.host, uri.port )
      xml = nil
      http.start do |conn|
         data = "appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str ) }&output=xml"
         # p data
         res, = conn.post( uri.path, data )
         xml = res.body
      end
      #p xml
      parser = LibXML::XML::Parser.string( xml )
      doc = parser.parse
      keywords = doc.find( "//y:Keyphrase", "y:urn:yahoo:jp:jlp:KeyphraseService" ).map{|e| e.content }
      #keywords.each do |e|
      #   p e.content
      #end
      keywords.select{|e| not e.nil? and not e.empty? }
   end

   def extract_keywords_mecab( str, method = :default )
      mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
      lines = mecab.parse( str.toeuc )
      #puts lines
      lines = lines.toutf8.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK|形容詞/o and l[1] !~ /接[頭尾]|非自立|代名詞/o }
      #p lines
      raise "Extracting keywords from a text failed." if lines.empty?
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
      count = Hash.new( 0 )
      score = 0
      lines.each_with_index do |line, idx|
         # ASCII symbol chars
         next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f、「『』]+\Z/o
         # Stop words, derived from Lucene
         next if line[0] =~ /\A(?:w(?:h(?:e(?:re(?:a(?:[st]|fter)|u(?:nto|pon)|in(?:to)?|o[fn]?|from|with|ver|by)?|n(?:(?:so)?ever|ce)?|ther)|o(?:m(?:(?:so)?ever)?|s(?:oever|e)|ever|le)?|i(?:ch(?:(?:so)?ever)?|l(?:st|e)|ther)|at(?:(?:so)?ever)?|y)|i(?:th(?:out|in)?|ll)|e(?:ll|re)?|ould|as)|a(?:l(?:(?:bei|mos)t|on[eg]|though|ready|ways|so|l)|n(?:y(?:(?:wher|on)e|thing|how)?|other|d)?|fter(?:wards)?|bo(?:ut|ve)|gain(?:st)?|mong(?:st)?|r(?:ound|e)|(?:cros)?s|dj|t)?|t(?:h(?:e(?:re(?:(?:upo|i)n|afte|for|by)?|m(?:selves)?|n(?:ce)?|ir|se|y)?|r(?:ough(?:out)?|u)|o(?:ugh|se)|[iu]s|a[nt])|o(?:gether|wards?|o)?)?|s(?:o(?:me(?:t(?:imes?|hing)|(?:wher|on)e|how)?)?|e(?:em(?:ing|ed|s)?|veral)|(?:inc|am)e|h(?:ould|e)|till|uch)?|b(?:e(?:c(?:om(?:es?|ing)|a(?:us|m)e)|fore(?:hand)?|(?:hi|yo)nd|(?:twe)?en|sides?|ing|low)?|oth|ut|y)|h(?:e(?:r(?:e(?:(?:upo|i)n|by)?|s(?:elf)?)?|eafter|nce)?|i(?:m(?:self)?|s)|a(?:[ds]|ve)|ow(?:ever)?)|o(?:u(?:r(?:(?:selve)?s)?|t)|n(?:ce one|ly|to)?|ther(?:wise|s)?|f(?:ten|f)?|(?:ve)?r|wn)|e(?:ve(?:r(?:y(?:(?:wher|on)e|thing)?)?|n)|ls(?:ewher)?e|(?:noug|ac)h|ither|xcept|tc|g)|n(?:o(?:[rw]|t(?:hing)?|body|o?ne)?|e(?:ver(?:theless)?|ither|xt)|amely|where)|m(?:o(?:re(?:over)?|st(?:ly)?)|(?:eanwhil)?e|u(?:ch|st)|y(?:self)?|an?y|ight)|i(?:[efs]|n(?:deed|to|c)?|t(?:s(?:elf)?)?)?|f(?:or(?:mer(?:ly)?)?|urther|irst|rom|ew)|l(?:a(?:tter(?:ly)?|st)|e(?:ast|ss)|td)|y(?:ou(?:r(?:s(?:el(?:ves|f))?)?)?|et)|x(?:author|other |note|subj|cal)|u(?:n(?:der|til)|p(?:on)?|s)|c(?:an(?:not)?|o(?:uld)?)|d(?:uring|own)|per(?:haps)?|v(?:ery|ia)|rather)\Z/o
         #next if line[0].size < 3
         #p line[2]
         #puts line.join("\t")
         case method
         when :tf
            score = 1
         when :count
            score = line[2].to_i
         else
            score = Math.log2( line[2].to_i + 1 )
         end
         #p [ line[0], score, idx ]
         count[ line[0] ] += score #/ Math.log2( idx + 1 )
         #count[ line[0] ] += 1
      end
      # $KCODE = "u"
      # p count
      ranks = count.keys.sort_by{|e| count[e] }.reverse.map{|e| [e,count[e]] }
      #pp ranks
      #3.times do |i|
      #   puts [ i+1, ranks[i], count[ ranks[i] ] ].join( "\t" )
      #end
      ranks
   end

   # Supports redirect
   def http_get( uri, limit = 3 )
      #STDERR.puts uri
      raise "Too many redirects: #{ uri }" if limit < 0
      http_proxy = ENV[ "http_proxy" ]
      proxy, proxy_port = nil
      if http_proxy
         proxy_uri = URI.parse( http_proxy )
         proxy = proxy_uri.host
         proxy_port = proxy_uri.port
      end
      http = Net::HTTP.Proxy( proxy, proxy_port ).new( uri.host, uri.port )
      http.use_ssl = true if uri.scheme == "https"
      http.start do |http|
         response, = http.get( uri.request_uri, { 'User-Agent'=>USER_AGENT } )
         #if response.code !~ /^2/
         #   response.each do |k,v|
         #      p [ k, v ]
         #   end
         #end
         case response
         when Net::HTTPSuccess
            response
         when Net::HTTPRedirection
            redirect_uri = URI.parse( response['Location'] )
            STDERR.puts "redirect to #{ redirect_uri } (#{limit})"
            http_get( uri + redirect_uri, limit - 1 )
         else
            response.error!
         end
      end
   end

   CACHE_DIR = "cache"
   def cache_xml( prefix, name, page = 0 )
      xml_fname = name.dup
      if xml_fname.size > 245
         xml_fname = Digest::MD5.hexdigest( xml_fname )
      end
      xml_fname << ":#{ page }" if not page.nil? and not page == 0
      xml_fname << ".xml"
      File.join( CACHE_DIR, prefix, xml_fname )
   end

   def pdftotext( pdf_str )
      pdf_file = Tempfile.new( [ "pdf", ".pdf" ] )
      pdf_file.print pdf_str
      pdf_file.flush
      #p pdf_file.size
      IO.popen( "/usr/local/bin/pdftotext -raw -enc EUC-JP #{ pdf_file.path } -" ) do |io|
         io.read
      end
   end

   # CiNii Opensearch APi
   def cinii_search( keyword, opts = {} )
      base_uri = "http://ci.nii.ac.jp/opensearch/search"
      q = URI.escape( keyword )
      cont = nil
      cache_file = cache_xml( "cinii", q, opts[:start] )
      #p File.mtime( cache_file )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         # TODO: Atom/RSSの双方を対象にできるようにすること（現状は Atom のみ）
         opts[ :format ] = "atom"
         if not opts.empty?
            opts_s = opts.keys.map do |e|
               "#{ e }=#{ URI.escape( opts[e].to_s ) }"
            end.join( "&" )
         end
         opensearch_uri = URI.parse( "#{ base_uri }?q=#{ q }&#{ opts_s }" )
         response = http_get( opensearch_uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      data[ :q ] = keyword
      data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" )
      data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content.to_i
      entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
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

   # NDL Porta Opensearch
   def ndl_search( keyword, opts = {} )
      base_uri = "http://api.porta.ndl.go.jp/servicedp/opensearch"
      q = URI.escape( keyword )
      cont = nil
      cache_file = cache_xml( "ndl", q, opts[:start] )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         opts[ :format ] = "atom"
         opts[ :dpgroupid ] = "ndl"
         if not opts.empty?
            opts_s = opts.keys.map do |e|
               "#{ e }=#{ URI.escape( opts[e].to_s ) }"
            end.join( "&" )
         end
         opensearch_uri = URI.parse( "#{ base_uri }?any=#{ q }&#{ opts_s }" )
         response = http_get( opensearch_uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      data[ :q ] = keyword
      data[ :link ] = "http://porta.ndl.go.jp/cgi-bin/openurl.cgi"
      data[ :totalResults ] = doc.find( "//openSearch:totalResults", "http://a9.com/-/spec/opensearchrss/1.0/" )[0].content.to_i
      entries = doc.find( "//item" )
      data[ :entries ] = []
      entries.each do |e|
         dpid = e.find( "./dcndl_porta:dpid", "http://ndl.go.jp/dcndl/dcndl_porta/" )[0].content
         title = e.find( "./title" )[0].content
         url = e.find( "./link" )[0].content
         author = e.find( ".//author" )
         if author and author[0]
            author = author[0].content
         else
            author = ""
         end
         source = e.find( "./source" )
         if source and source[0]
            source = source[0].content
         else
            source = ""
         end
         publicationName = e.find( "dcterms:bibliographicCitation", "http://purl.org/dc/terms/" )
         if publicationName and publicationName[0]
            publicationName = publicationName[0].content
         else
            publicationName = nil
         end
         date = e.find( "./dcterms:issued", "http://purl.org/dc/terms/" )
         if date and date[0]
            date = date[0].content
         else
            date = e.find( "./dcterms:modified", "http://purl.org/dc/terms/" )
            if date and date[0]
               date = date[0].content
            else
               date = nil
            end
         end
         publisher = e.find( "./dc:publisher", "http://purl.org/dc/elements/1.1/" )
         if publisher and publisher[0]
            publisher = publisher[0].content
         else
            publisher = nil
         end
         description = e.find( "./description" )
         if description and description[0] and dpid != "zassaku"
            description = description[0].content
         else
            description = ""
         end
         if publicationName.nil? or publicationName.empty?
            publicationName = [ source, publisher ].select{|e|
               not e.nil? and not e.empty?
            }.join( "; " )
         end
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :source => source,
            :date => date,
            :publicationDate => date,
            :publisher => publisher,
            :publicationName => publicationName,
            :description => description,
            :dpid => dpid,
         }
      end
      data
   end

   # レファ協API via NDL PORTA Opensearch
   def crd_search2( keyword, opts = {} )
      base_uri = "http://api.porta.ndl.go.jp/servicedp/opensearch"
      q = URI.escape( keyword )
      cont = nil
      cache_file = cache_xml( "crd2", q, opts[:start] )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         opts[ :format ] = "atom"
         opts[ :dpid ] = "refkyo"
         if not opts.empty?
            opts_s = opts.keys.map do |e|
               "#{ e }=#{ URI.escape( opts[e].to_s ) }"
            end.join( "&" )
         end
         opensearch_uri = URI.parse( "#{ base_uri }?any=#{ q }&#{ opts_s }" )
         response = http_get( opensearch_uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      data[ :q ] = keyword
      data[ :link ] = "http://porta.ndl.go.jp/cgi-bin/openurl.cgi"
      data[ :totalResults ] = doc.find( "//openSearch:totalResults", "http://a9.com/-/spec/opensearchrss/1.0/" )[0].content.to_i
      entries = doc.find( "//item" )
      data[ :entries ] = []
      entries.each do |e|
         dpid = e.find( "./dcndl_porta:dpid", "http://ndl.go.jp/dcndl/dcndl_porta/" )[0].content
         title = e.find( "./title" )[0].content
         url = e.find( "./link" )[0].content
         author = e.find( ".//author" )
         if author and author[0]
            author = author[0].content
         else
            author = ""
         end
         source = e.find( "./source" )
         if source and source[0]
            source = source[0].content
         else
            source = ""
         end
         publicationName = e.find( "dcterms:bibliographicCitation", "http://purl.org/dc/terms/" )
         if publicationName and publicationName[0]
            publicationName = publicationName[0].content
         else
            publicationName = nil
         end
         date = e.find( "./dcterms:issued", "http://purl.org/dc/terms/" )
         if date and date[0]
            date = date[0].content
         else
            date = e.find( "./dcterms:modified", "http://purl.org/dc/terms/" )
            if date and date[0]
               date = date[0].content
            else
               date = nil
            end
         end
         publisher = e.find( "./dc:publisher", "http://purl.org/dc/elements/1.1/" )
         if publisher and publisher[0]
            publisher = publisher[0].content
         else
            publisher = nil
         end
         description = e.find( "./description" )
         if description and description[0] and dpid != "zassaku"
            description = description[0].content
         else
            description = ""
         end
         if publicationName.nil? or publicationName.empty?
            publicationName = [ source, publisher ].select{|e|
               not e.nil? and not e.empty?
            }.join( "; " )
         end
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :source => source,
            :date => date,
            :publicationDate => date,
            :publisher => publisher,
            :publicationName => publicationName,
            :description => description,
            :dpid => dpid,
         }
      end
      data
   end

   # レファレンス協同データベースAPI
   def crd_search( keyword, opts = {} )
      require "htmlentities"
      base_uri = "http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI"
      q = URI.escape( keyword )
      opts[ :query_logic ] = "2"
      opts_s = ""
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e].to_s ) }"
         end.join( "&" )
      end
      query = "01_" + q + ".02_" + q
      opts_s = "&" + opts_s if not opts_s.empty?
      uri = URI.parse( "#{ base_uri }?query=#{ query }#{ opts_s }" )
      cont = nil
      cache_file = cache_xml( "crd", q, opts[:start] )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         response = http_get( uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = nil
      begin
         doc = parser.parse
      rescue LibXML::XML::Error => e
         File.unlink( cache_file )
         raise e
      end
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      data[ :q ] = keyword
      #data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" )
      data[ :link ] = "http://crd.ndl.go.jp/" # TODO: リンク先を適宜補完すること。
      data[ :totalResults ] = doc.find( "//crd:hit_num", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content.to_i
      entries = doc.find( "//crd:result", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./crd:QUESTION", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content
         url = e.find( "./crd:URL", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content
         author = e.find( "./crd:LIB-NAME", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" ).to_a.map{|name| name.content }.join( "; " )
         description = e.find( "./crd:ANSWER", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content
         if description.nil? or description.empty?
            description = e.find( "./crd:ANS-PROC", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content
         end
         pubdate = e.find( "./crd:CRT-DATE", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0]
         pubdate = pubdate ? pubdate.content : e.find( "./crd:REG-DATE", "crd:http://crd.ndl.go.jp/refapi/servlet/refapi.RSearchAPI" )[0].content
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :description => description,
            :publicationDate => pubdate,
         }
      end
      data
   end

   # WorldCat Basic API (Opensearch)
   WORLDCAT_BASIC_WSKEY = "5lIR8i5bSQQNg4Xb3ro6QbOzXiGSs6PrGGJ02BKolP9qTUQRcui2Ze9AsQIlM8IzV0E9XMcrWWieWvrM"
   def worldcat_search( keyword, opts = {} )
      base_uri = "http://worldcat.org/webservices/catalog/search/opensearch"
      q = URI.escape( keyword )
      cont = nil
      cache_file = cache_xml( "worldcat", q, opts[:start] )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         opts[ :format ] = "atom"
         opts[ :wskey ] = WORLDCAT_BASIC_WSKEY
         if not opts.empty?
            opts_s = opts.keys.map do |e|
               "#{ e }=#{ URI.escape( opts[e].to_s ) }"
            end.join( "&" )
         end
         opensearch_uri = URI.parse( "#{ base_uri }?q=#{ q }&#{ opts_s }" )
         response = http_get( opensearch_uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      data[ :q ] = keyword
      # data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" ).sub( /&wskey=\w+/, "" )
      data[ :link ] = "http://www.worldcat.org/search?q=#{ q }"
      data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content.to_i
      entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
         url = e.find( "./atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content
         author = e.find( ".//atom:author/atom:name", "atom:http://www.w3.org/2005/Atom" ).to_a.map{|name| name.content }.join( "; " )
         content = e.find( "./atom:content", "atom:http://www.w3.org/2005/Atom" )[0]
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :content => content,
            :publicationName => content,
         }
      end
      data
   end

   # 一橋大学 OPAC Opensearch (not API)
   def opac_hit_u_search( keyword, opts = {} )
      require "htmlentities"
      base_uri = "https://opac.lib.hit-u.ac.jp/opac/opac_list.cgi"
      q = URI.escape( keyword )
      opts_s = ""
      opts[ :amode ] = 9 if opts.key?( :key )
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e].to_s ) }"
         end.join( "&" )
      end
      opts_s = "&" + opts_s if not opts_s.empty?
      uri = URI.parse( "#{ base_uri }?kywd=#{ q }#{ opts_s }" )
      cont = nil
      cache_file = cache_xml( "opac_hit_u", q, opts[:start] )
      if File.exist?( cache_file ) and ( Time.now - File.mtime( cache_file ) ) < CACHE_TIME
         cont = open( cache_file ){|io| io.read }
      else
         response = http_get( uri )
         cont = response.body
         open( cache_file, "w" ){|io| io.print cont }
      end
      data = {}
      # <td class="list_result"><span class="name"><a href="/opac/opac_details.cgi?lang=0&amode=11&place=&bibid=1000258087&key=B126875030611669&start=1&srmode=0"><strong>Take the test : sample questions from OECD's PISA assessments</strong></a></span><div class="other">[Paris] : OECD , c2009.</div></td>
      data[ :opac_hit_u_key ] = $1 if %r[&key=(\w+)&] =~ cont # ad-hoc...
      data[ :q ] = keyword
      data[ :link ] = uri.to_s
      if %r[該当件数(?:&nbsp;|[:\s])*<b>(\d+)</b>&nbsp;件] =~ cont
         totalResults = $1.to_i
      else
         totalResults = 0
      end
      htmlentities = HTMLEntities.new
      data[ :totalResults ] = totalResults
      data[ :entries ] = []
      cont.gsub( %r|<td class="list_result"><span class="name"><a href="([^\"]+)"><strong>([^<]*)</strong></a></span><div class="other">(.*?)</div></td>| ) do |entry|
         url, title, other = $1, $2, $3
         url = uri.merge( $1 )
         if url.query =~ /(bibid=\w+)/
            url.query = "amode=11&#$1"
         end
         title = htmlentities.decode( title )
         author = ""
         if title =~ / \/ /
            #STDERR.puts title.split( / \/ / )
            title, author = title.split( / \/ / )
         end
         other.gsub!( /<[^>]+>/, "" )
         other = htmlentities.decode( other )
         case other
         when /c?(\d{4})\.\Z/, /\b(\d{4}[\.\d+])\.\Z/
            date = $1
         when other =~ /c?(\d{4})\./
            date = $1
         end
         data[ :entries ] << {
            :title => title,
            :author => author,
            :url => url,
            :description => other,
            :publicationDate => date,
         }
      end
      data
   end

   class NoHitError < Exception; end

	class Message < Hash
		ERROR_MESSAGE = {
			"Fuwatto::NoHitError" => "関連する文献を見つけることができませんでした。",
		}
		def initialize
			set = ERROR_MESSAGE.dup
		end
	end


   class BaseApp
      attr_reader :format, :content, :url
      attr_reader :count, :page, :mode
      def initialize( cgi )
         @cgi = cgi
         @url = @cgi.params["url"][0]
         @content = @cgi.params["text"][0]
         @format = @cgi.params["format"][0] || "html"
         @count = @cgi.params["count"][0].to_i
         @count = 20 if count < 1
         @page = @cgi.params["page"][0].to_i
         @mode = @cgi.params["mode"][0] || "mecab"
         @callback = @cgi.params["callback"][0]
      end

      def query_url?
         not url.nil? and not url.empty? and url != "http://"
      end
      def query_text?
         not content.nil? and not content.empty?
      end
      def query?
         query_url? or query_text?
      end

      include Fuwatto
      def execute( search_method, terms, opts = {} )
         data = {}
         if not query?
            return data
         end
         time_pre = Time.now
         if query_url?
            uri = URI.parse( url )
            response = http_get( uri )
            @content = response.body
            case response[ "content-type" ]
            when /^text\/html\b/
               @content = @content
               @content = ExtractContent::analyse( @content ).join( "\n" )
               #puts content
            when /^text\//
               @content = @content
            when /^application\/pdf\b/
               @content = pdftotext( @content )
            else
               raise "Unknown Content-Type: #{ response[ "content-type" ] }"
            end
         end
         vector = Document.new( content, mode )
         #vector[0..20].each do |e|
         #   puts e.join("\t")
         #end
         prev_scores = []
         vector1 = Document.new( nil ) # empty vector
         while vector.size > 0
            k = vector.shift
            prev_scores << k[1]
            res = send( search_method, k[0], opts )
            next if res[ :totalResults ] < 1
            score = k[1] * 1 / Math.log2( res[ :totalResults ] + 1 )
            vector1 << [ k[0], score ]
            break if vector1.size >= terms
         end
         raise Fuwatto::NoHitError if vector1.empty?
         vector1 = vector1.sort_by{|k| -k[1] }
         prev_min = prev_scores.min
         cur_min  = vector1[-1][1]
         vector = vector.map do |k|
            factor = prev_min / cur_min
            score = k[1] / factor
            [ k[0], score ]
         end
         vector = vector1 + vector
         #p vector
         #vector[0..20].each do |e|
         #   puts e.join("\t")
         #end
         #p vector
         keywords = {}
         vector[ 0..20 ].each do |k,v|
            keywords[ k ] = v
         end
         keyword = ""
         entries = []
         additional_keywords = []
         terms.times do |i|
            keyword = vector[ 0..(terms-i-1) ].map{|k| k[0] }.join( " " )
            STDERR.puts keyword
            data = send( search_method, keyword, opts )
            if data[ :totalResults ] > 0
               entries = ( entries + data[ :entries ] ).uniq
               if entries.size < count and entries.size <= count * ( page + 1 ) and vector.size >= (terms-i)
                  additional_keywords.unshift( vector[ terms - i - 1 ][0] )
                  #p additional_keywords
                  next
               else
                  start = count + 1
                  while data[ :totalResults ] >= start and entries.size < count * ( page + 1 ) do
                     #p [ entries.size, start ]
                     opts[ :start ] = start
                     opts[ :key ] = data[ :opac_hit_u_key ] if data[ :opac_hit_u_key ]
                     data = send( search_method, keyword, opts )
                     entries = ( entries + data[ :entries ] ).uniq
                     start += count
                  end
               end
               break
            end
         end
         data[ :keywords ] = keywords
         data[ :entries ] = entries
         data[ :entries ] = entries[0, @count] if @format == "json"
         data[ :additional_keywords ] = additional_keywords
         data[ :count ] = count
         data[ :page ] = page
         data[ :database ] = self.class.to_s.sub( /\AFuwatto::(\w+)App\Z/, '\1' ).downcase
         data[ :searchTime ] = "%0.02f" % ( Time.now - time_pre )
         data
      end

      def output( prefix, data = {} )
         #STDERR.puts data.inspect
         case format
         when "html"
            result = eval_rhtml( "./#{ prefix }.rhtml", binding ) if query? and not data.has_key?( :error )
            print @cgi.header
            print eval_rhtml( "./#{ prefix }_top.rhtml", binding )
         when "json"
            print @cgi.header "application/json"
            result = JSON::generate( data )
            if @callback and @callback =~ /^\w+$/
               result = "#{ @callback }(#{ result })"
            end
            print result
         else
            raise "unknown format specified: #{ format }"
         end
      end

      include ERB::Util
      def eval_rhtml( fname, binding )
         rhtml = open( fname ){|io| io.read }
         result = ERB::new( rhtml, $SAFE, "<>" ).result( binding )
      end
   end
end
