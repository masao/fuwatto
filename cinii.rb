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
      cont
   end
end

if $0 == __FILE__
   puts "Content-Type: text/html\n\n"
   require "rexml/document"
   include Zubatto
   keyword = ARGV[0] || "information seeking"
   result = cinii_search( keyword, { :format => "atom" } )
   #open( "result.xml", "w" ){|io| io.puts result }
   data = {}
   parser = LibXML::XML::Parser.string( result )
   doc = parser.parse
   #puts doc.find( "//opensearch:totalResults" )[0].content
   data[ :q ] = keyword
   data[ :totalResults ] = doc.find( "//opensearch:totalResults" )[0].content
   entries = doc.find( "//atom:entry", "atom:http://www.w3.org/2005/Atom" )
   data[ :entries ] = []
   entries.each do |e|
      title = e.find( "./atom:title", "atom:http://www.w3.org/2005/Atom" )[0].content
      url = e.find( "./atom:id", "atom:http://www.w3.org/2005/Atom" )[0].content
      author = e.find( ".//atom:author/atom:name", "atom:http://www.w3.org/2005/Atom" ).to_a.map{|name| name.content }.join( "; " )
      data[ :entries ] << {
         :title => title,
         :url => url,
         :author => author,
      }
   end
   rhtml = open("cinii.rhtml"){|io| io.read }
   include ERB::Util
   puts ERB::new( rhtml, $SAFE, 2 ).result( binding )
end
