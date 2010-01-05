#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require "nkf"
require "yaml"
require "rubygems"
require "libxml"

begin
   require 'sqlite3'
   DBTYPE = SQLite3::Database
rescue LoadError
   require 'dbi'
   DBTYPE = DBI
end

require "database.rb"
require "harvester.rb"

module Fuwatto
   class Util
      def self.ja_char_normalizer( str )
         NKF.nkf( "-tXZ1", str ).gsub( /\s+/, " " ).strip
      end
      def self.space_normalizer( str )
         str.gsub( /\s+/, " " ).strip
      end
   end
end

if $0 == __FILE__
   include Fuwatto
   harvester = Harvester.new( "harvester.conf" )
   harvester.sites.each do |site|
      p site
      logfile = open("log/indexer.#{site}.#{Time.now.strftime("%Y%m%d%H%M%S")}", "w")
      Dir.glob( "#{ Harvester::HARVEST_DIR  }/#{ site }/*.xml" ) do |file|
         p file
         parser = LibXML::XML::Parser.file( file )
         doc = parser.parse
         records = doc.find( "//oai:ListRecords/oai:record",
                             "oai:http://www.openarchives.org/OAI/2.0/" )
         # p records.empty?
         records.each do |record|
            node = record.find( "oai:header/oai:identifier",
                                "oai:http://www.openarchives.org/OAI/2.0/" )
            identifier = node.first.content
            #p identifier
            junii2 = record.find( "oai:metadata/ju:junii2",
                                  ["ju:http://ju.nii.ac.jp/junii2",
                                   "oai:http://www.openarchives.org/OAI/2.0/" ])
            if junii2.empty?
               junii2 = record.find( "oai:metadata/irdb:junii2",
                                     ["irdb:http://irdb.nii.ac.jp/oai",
                                      "oai:http://www.openarchives.org/OAI/2.0/" ])
            end
            if junii2.empty?
               # ad-hoc workaround for Tulips-R
               junii2 = record.find( "oai:metadata/irdb:meta",
                                     ["irdb:http://irdb.nii.ac.jp/dspace-oai",
                                      "oai:http://www.openarchives.org/OAI/2.0/" ])
            end
            next if junii2.empty?
            junii2.each do |md|
               data = Hash.new( "" )
               data[ "identifier" ] = identifier
               md.children.each do |e|
                  case e.name
                  when "text"
                     next
                  when "description", "title", "jtitle", "creator", "alternative", "subject", "NIIsubject", "publisher", "contributor", "type", "source"
                     str = Util.space_normalizer( e.content )
                     if data[ e.name ].empty?
                        data[ e.name ] = str
                     else
                        data[ e.name ] << " " << str
                     end
                  end
               end
               db = Database.new( DBTYPE )
               indexed_data = %w[ identifier description title jtitle creator alternative subject NIIsubject publisher contributor type source ].map{|e| data[e] }
               db.transaction do
                  begin
                     sth = db.prepare("INSERT INTO md VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                     sth.execute( 0, *indexed_data )
                  rescue SQLite3::SQLException => e
                     open( "error.tmp", "w" ) do |io|
                        io.puts indexed_data.inspect
                        io.puts indexed_data.size
                     end
                     raise e
                  end
                  logfile.puts [ data[ "identifier"], data[ "title" ] ].join("\t")
               end
               #p [ indexed_data, indexed_data.size ]
               #rows = db.execute( "SELECT * from md" )
               #p rows.size
               #sleep 5
            end
            # puts "---"
         end
      end
   end
end
