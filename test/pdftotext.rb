#!/usr/bin/env ruby
# $Id$

$LOAD_PATH.push File.join( "../", File.dirname( $0 ) )
require "cinii.rb"

file = ARGV[0]
include Fuwatto
p Fuwatto.pdftotext( open(file){|f| f.read } )
