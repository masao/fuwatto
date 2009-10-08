#!/usr/bin/env ruby
# $Id$

require "time"
require "yaml"
require "rubygems"
require "oai"
# require "oai/harvester"

module Zubatto
   class Harvester
      attr_reader :sites, :conf
      def initialize( config_file )
         @conf = YAML.load_file( config_file )
         @sites = @conf.keys
      end
      def start
         time = Time.now
         sites.each do |site|
            puts site
            puts conf[ site ][ "url" ]
            options = build_options_hash( conf[ site ] )
            oai = OAI::Client.new( conf[ site ][ "url" ], options )
            # provider_config = oai.identify
            # p provider_config
            options.delete( :url )
            response = oai.list_records( options )
            open( "#{ site }-#{ time.to_i }.xml", "w" ) do |io|
               io.print response.doc
            end
            count = 2
            while response.resumption_token
               puts "resumptionToken: #{ response.resumption_token }"
               response = oai.list_records( :resumptionToken => response.resumption_token )
               open( "#{ site }-#{ time.to_i }-#{ count }.xml", "w" ) do |io|
                  io.print response.doc
               end
               count += 1
            end
         end
      end
      def last_harvest_time( site )
         files = Dir.glob( "#{site}-*.xml" )
         if files.nil? or files.empty?
            nil
         else
            files.sort_by{|e|
               e =~ /\A#{ site }-(\d+)\.xml\Z/
               $0.to_i
            }[-1]
         end
      end
      def build_options_hash( site )
         options = { :url => site['url'] }
         options[:set] = site['set'] if site['set']
         options[:from] = site['last'].utc.xmlschema if site['last']
         options[:metadata_prefix] = site['prefix'] if site['prefix']
         options
      end
   end
end

if $0 == __FILE__
   crawler = Zubatto::Harvester.new( "harvester.conf" )
   crawler.start
   # conf = YAML.load_file( "harvester.conf" )
   # crawler = OAI::Harvester::Harvest.new
   # crawler.start
end
