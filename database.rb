#!/usr/bin/env ruby
# $Id$

module Zubatto
   class Database
      DATABASE_NAME = "md.db"
      CREATE_TABLE = <<-EOF
	CREATE TABLE IF NOT EXISTS md (
		indexed INTEGER,
		identifier TEXT,
		description TEXT,
		title TEXT,
		jtitle TEXT,
		creator TEXT,
		alternative TEXT,
		subject TEXT,
		NIIsubject TEXT,
		publisher TEXT,
		contributor TEXT,
		type TEXT,
		source TEXT
	       );
	EOF
      def initialize( klass )
         @klass = klass
         if @klass.name == "DBI"
            @db = @klass.connect(DATABASE_NAME)
         elsif @klass.name == "SQLite3::Database"
            @db = @klass.new(DATABASE_NAME)
         else
            raise "unknown dbtype: #{klass}"
         end
         @db.execute( CREATE_TABLE )
         #STDERR.puts "INFO: #{ DATABASE_NAME.inspect } not found. New database is created."
      end
      def method_missing( name, args = nil, &block )
         if @db.respond_to?( name )
            if args.nil?
               @db.send( name, &block )
            else
               @db.send( name, *args, &block )
            end
         else
            raise NameError::new( "method_missing: #{name}: #{args}" )
         end
      end
   end
end
