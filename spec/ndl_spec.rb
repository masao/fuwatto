#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# $Id$

require_relative "../ndl.rb"

describe Fuwatto do
  describe "#iss_ndl_search" do
    include Fuwatto
    it "should work with keyword search" do
      result = iss_ndl_search( "keyword" )
      expect( result ).not_to be_empty
      expect( result ).to have_key :link
      expect( result ).to have_key :q
      expect( result[:q] ).to eq "keyword"
      expect( result[:totalResults] ).to be > 0
      expect( result[:entries].size ).to be > 0
    end
    it "should work with isbn search" do
      result = iss_ndl_search( "yahoo" )
      expect( result ).not_to be_empty
      expect( result[:entries].size ).to be > 0
      isbncount = 0
      result[:entries].each do |e|
         isbncount += 1 if e[ :isbn ]
      end
      expect( isbncount ).to be > 0
    end
  end
end

describe Fuwatto::NDLApp do
  before :each do
    ENV[ "REQUEST_METHOD" ] = "GET"
    @cgi = CGI.new( nil )
  end

  it "#execute works" do
    @cgi.params["url"] = [ "http://yahoo.co.jp" ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 0
    expect( result[ :totalResults ] ).to be > 20
  end
  it "#output works" do
    @cgi.params["url"] = [ "http://yahoo.co.jp" ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    $stdout = StringIO.new( "", "r+" )
    app.output( "ndl", result )
    $stdout.rewind
    expect( $stdout.read ).to match( /<html/i )
  end
  it "should work with text search" do
    @cgi.params[ "text" ] = [ "児童虐待と相談所の運営" ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 0
  end
  it "should support pagination" do
    @cgi.params["url"] = [ "http://yahoo.co.jp" ]
    @cgi.params["page"] = [ 1 ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 20
  end
  it "should support pagination with text search" do
    @cgi.params[ "text" ] = [ "イレッサ 承認" ]
    @cgi.params["page"] = [ 1 ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 20

    @cgi.params["page"] = [ 2 ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 20
    expect( result[ :entries ].size ).to be > 0

    @cgi.params["page"] = [ 12 ]
    app = Fuwatto::NDLApp.new( @cgi )
    result = app.execute
    expect( result ).not_to be_empty
    expect( result[ :totalResults ] ).to be > 0
    expect( result[ :entries ].size ).to be > app.count * app.page
  end
end
