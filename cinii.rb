#!/usr/local/bin/ruby
# $Id$

require "open-uri"
require "pp"
require "erb"
require "rubygems"
require "libxml"

module Zubatto
   def cinii_search( keyword, opts = {} )
      base_uri = "http://ci.nii.ac.jp/opensearch/search"
      q = URI.escape( keyword )
      if not opts.empty?
         opts_s = opts.keys.map do |e|
            "#{ e }=#{ URI.escape( opts[e] ) }"
         end.join( "&" )
      end
      cont = nil
      open( "#{ base_uri }?q=#{ q }&#{ opts_s }" ) do |res|
         cont = res.read
      end
      #open( "result.xml", "w" ){|io| io.puts cont }

      data = {}
      parser = LibXML::XML::Parser.string( cont )
      doc = parser.parse
      # ref. http://ci.nii.ac.jp/info/ja/if_opensearch.html
      #puts keyword
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
            pubname = e.find( "./dc:publisher", "dc:http://purl.org/dc/elements/1.1/" )[0].content
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
end

if $0 == __FILE__
   puts "Content-Type: text/html\n\n"
   include Zubatto
   keyword = ARGV[0] || "information seeking"
   data = cinii_search( keyword, { :format => "atom" } )
   data[ :count ] = 5
   rhtml = open("cinii.rhtml"){|io| io.read }
   include ERB::Util
   puts ERB::new( rhtml, $SAFE, 2 ).result( binding )
end
