#!/usr/bin/env ruby
# $Id$

require "fileutils"
require "time"
require "yaml"
require "rubygems"
require "oai"
# require "oai/harvester"

module Fuwatto
   class Harvester
      HARVEST_DIR = "harvest"
      attr_reader :sites, :conf
      def initialize( config_file )
         @conf = YAML.load_file( config_file )
         @sites = @conf.keys
      end
      def start
         now = Time.now
         sites.each do |site|
            puts site
            opts = build_options_hash( conf[ site ] )
            opts[ :until ] = now.utc.xmlschema
            last_updated = last_harvest_time( site )
            # p last_updated
            unless last_updated.nil? or last_updated == 0
               opts[ :from ] = Time.at( last_updated ).utc.xmlschema
               puts "last updated: #{ opts[ :from ] }"
            else
               opts[ :from ] = earliest( opts[:url] )
               last_updated = 0
            end
            puts opts[ :url ]
            period = 60 * 60 * 24 # default rotation is "daily".
            case opts[ :period ]
            when "daily"
               period = 60 * 60 * 24
            when "weekly"
               period = 60 * 60 * 24 * 7
            end
            if ( now.to_i - last_updated ) < period # and false
               puts "interval skip: last updated at #{ Time.at( last_updated ).iso8601 }"
               next
            end
            p opts
            oai = OAI::Client.new( opts[ :url ], opts )
            opts.delete( :url )
            opts.delete( :period )
            response = oai.list_records( opts )
            FileUtils.mkdir_p( File.join( HARVEST_DIR, site ) )
            open( "#{ HARVEST_DIR }/#{ site }/#{ now.to_i }.xml", "w" ) do |io|
               io.print response.doc
            end
            count = 2
            while response.resumption_token
               puts "resumptionToken: #{ response.resumption_token }"
               response = oai.list_records( :resumptionToken => response.resumption_token )
               open( "#{ HARVEST_DIR }/#{ site }/#{ now.to_i }-#{ count }.xml", "w" ) do |io|
                  io.print response.doc
               end
               count += 1
            end
         end
      end
      def last_harvest_time( site )
         files = Dir.glob( "#{ HARVEST_DIR }/#{ site }/*.xml" )
         # p "#{ HARVEST_DIR }/#{ site }/*.xml"
         # p files
         if files.nil? or files.empty?
            puts "Files not found. This is the first harvesting!"
            nil
         else
            files = files.map{|e|
               /\A(\d+)\.xml\Z/ =~ File.basename( e )
               $1.to_i
            }.compact
            # p files
            files.sort[-1]
         end
      end
      # Get earliest timestamp from repository
      def earliest(url)
         client = OAI::Client.new url
         identify = client.identify
         if "YYYY-MM-DD" == identify.granularity
            Time.parse(identify.earliest_datestamp).strftime("%Y-%m-%d")
         else
            Time.parse(identify.earliest_datestamp).xmlschema
         end
      end
      def build_options_hash( site )
         options = { :url => site['url'] }
         options[:set] = site['set'] if site['set']
         options[:metadata_prefix] = site['prefix'] if site['prefix']
         options
      end
   end
end

if $0 == __FILE__
   crawler = Fuwatto::Harvester.new( "harvester.conf" )
   crawler.start
   # conf = YAML.load_file( "harvester.conf" )
   # crawler = OAI::Harvester::Harvest.new
   # crawler.start
end
