#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
# $Id$

require "net/http"
#require "pp"
require "tempfile"
require "erb"
require "cgi"
require "nkf"
require "kconv"

require "rubygems"
require "json"
require "libxml"
require "MeCab"
require "extractcontent"

module Math
   def self::log2( n )
      Math.log10( n ) / Math.log10( 2 )
   end
end

module Fuwatto
   VERSION = '0.2'
   BASE_URI = 'http://fuwat.to/'
   USER_AGENT = "Fuwatto Search/#{ VERSION }; #{ BASE_URI }"
   CACHE_TIME = 60 * 60 * 24 * 1   # 1日経つまで、キャッシュは有効
   MAX_PAGE = 19 # ページネイションに表示されるアイテム数

   # Bag of Words による文書表現
   class Document < Array
      include Fuwatto
      attr_reader :content
      def initialize( content, mode = "mecab" )
         super()
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
            sum += v * self.assoc( k ).to_i
         end
         sum
      end
   end

   YAHOO_KEYWORD_BASEURI = "http://jlp.yahooapis.jp/KeyphraseService/V1/extract"
   YAHOO_APPID = "W11oHSWxg65mAdRwjBT4ylIdfS9PkHPjVvtJzx9Quwy.um8e1LPf_b.4usSBcmI-"
   def extract_keywords_yahooapi( str )
      #cont = open( "?appid=#{ YAHOO_APPID }&sentence=#{ URI.escape( str ) }&output=xml" ){|io| io.read }
      uri = URI.parse( YAHOO_KEYWORD_BASEURI )
      response = http_get( uri )
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

   def extract_keywords_mecab( str, method = :default )
      mecab = MeCab::Tagger.new( '--node-format=%m\t%H\t%c\n --unk-format=%m\tUNK\t%c\n' )
      lines = mecab.parse( str.toeuc )
      #puts lines
      lines = lines.toutf8.split( /\n/ ).map{|l| l.split(/\t/) }
      lines = lines.select{|l| l[2] and l[1] =~ /^名詞|UNK|形容詞/o and l[1] !~ /接[頭尾]|非自立|代名詞/o }
      #pp lines
      raise "Extracting keywords from a text failed." if lines.empty?
      min = lines.map{|e| e[2].to_i }.min
      lines = lines.map{|e| [ e[0], e[1], e[2].to_i + min.abs + 1 ] } if min < 0
      count = Hash.new( 0 )
      score = 0
      lines.each_with_index do |line, idx|
         next if line[0] =~ /\A[\x00-\x2f\x3a-\x40\x5b-\x60\x7b-\x7f]+\Z/o # ASCII symbol chars
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
         #pp [ line[0], score, idx ]
         count[ line[0] ] += score #/ Math.log2( idx + 1 )
         #count[ line[0] ] += 1
      end
      #pp count
      ranks = count.keys.sort_by{|e| count[e] }.reverse.map{|e| [e,count[e]] }
      #pp ranks
      #3.times do |i|
      #   puts [ i+1, ranks[i], count[ ranks[i] ] ].join( "\t" )
      #end
      ranks
   end

   # Supports redirect
   def http_get( uri, limit = 3 )
      raise "Too many redirects: #{ uri }" if limit < 0
      http_proxy = ENV[ "http_proxy" ]
      proxy, proxy_port = nil
      if http_proxy
         proxy_uri = URI.parse( http_proxy )
         proxy = proxy_uri.host
         proxy_port = proxy_uri.port
      end
      Net::HTTP.Proxy( proxy, proxy_port ).start( uri.host, uri.port ) do |http|
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
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      #puts keyword.toeuc
      data[ :q ] = keyword
      data[ :link ] = "http://porta.ndl.go.jp/cgi-bin/openurl.cgi"
      data[ :totalResults ] = doc.find( "//openSearch:totalResults", "http://a9.com/-/spec/opensearchrss/1.0/" )[0].content.to_i
      entries = doc.find( "//item" )
      data[ :entries ] = []
      entries.each do |e|
         dpid = e.find( "./dcndl_porta:dpid", "http://ndl.go.jp/dcndl/dcndl_porta/" )[0].content
         title = e.find( "./title" )[0].content
         #puts title.toeuc
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
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :source => source,
            :date => date,
            :publisher => publisher,
            :publicationName => publicationName,
            :description => description,
            :dpid => dpid,
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
      #puts keyword.toeuc
      data[ :q ] = keyword
      # data[ :link ] = doc.find( "//atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content.sub( /&format=atom\b/, "" ).sub( /&wskey=\w+/, "" )
      data[ :link ] = "http://www.worldcat.org/search?q=#{ q }"
      data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content.to_i
      entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
      data[ :entries ] = []
      entries.each do |e|
         title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
         #puts title.toeuc
         url = e.find( "./atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content
         author = e.find( ".//atom:author/atom:name", "atom:http://www.w3.org/2005/Atom" ).to_a.map{|name| name.content }.join( "; " )
         content = e.find( "./atom:content", "atom:http://www.w3.org/2005/Atom" )[0]
         data[ :entries ] << {
            :title => title,
            :url => url,
            :author => author,
            :content => content,
         }
      end
      data
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
      def execute( search_method, terms )
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
               @content = @content.toeuc
               @content = ExtractContent::analyse( @content ).join( "\n" )
               #puts content
            when /^text\//
               @content = @content.toeuc
            when /^application\/pdf\b/
               @content = pdftotext( @content ) #.toeuc
            else
               raise "Unknown Content-Type: #{ response[ "content-type" ] }"
            end
         end
         vector = Document.new( content, mode )
         vector1 = {}
         vector.each_with_index do |k, i|
            res = send( search_method, k[0].toutf8 )
            next if res[ :totalResults ] < 1
            score = k[1] * 1 / Math.log2( res[ :totalResults ] + 1 )
            vector1[ k[0] ] = score
            break if vector1.size >= 10
         end
         vector = vector1.keys.sort_by{|k| -vector1[k] }
         #puts vector1
         keyword = ""
         entries = []
         additional_keywords = []
         terms.times do |i|
            keyword = vector[ 0..(terms-i-1) ].join( " " ).toutf8
            STDERR.puts keyword
            data = send( search_method, keyword )
            if data[ :totalResults ] > 0
               entries = ( entries + data[ :entries ] ).uniq
               if entries.size < count and entries.size <= count * ( page + 1 ) and vector.size >= (terms-i)
                  additional_keywords.unshift( vector[ terms - i - 1 ].toutf8 )
                  #p additional_keywords
                  next
               else
                  start = count + 1
                  while data[ :totalResults ] >= start and entries.size < count * ( page + 1 ) do
                     #p [ entries.size, start ]
                     data = send( search_method, keyword, { :start => start } )
                     entries = ( entries + data[ :entries ] ).uniq
                     start += count
                  end
               end
               break
            end
         end
         data[ :entries ] = entries
         data[ :additional_keywords ] = additional_keywords
         data[ :count ] = count
         data[ :page ] = page
         data[ :searchTime ] = "%0.02f" % ( Time.now - time_pre )
         data
      end

      def output( prefix, data = {} )
         case format
         when "html"
            result = eval_rhtml( "./#{ prefix }.rhtml", binding ) if query?
            print @cgi.header
            print eval_rhtml( "./#{ prefix }_top.rhtml", binding )
         when "json"
            print @cgi.header "application/json"
            print JSON::generate( data )
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
