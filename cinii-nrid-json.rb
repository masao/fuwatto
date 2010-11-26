#!/usr/local/bin/ruby
# $Id$

require "fuwatto.rb"

include Fuwatto

@cgi = CGI.new

callback = @cgi.params[ "callback" ][ 0 ]
name = @cgi.params[ "name" ][ 0 ]
naid = @cgi.params[ "naid" ]

data = cinii_author_nrid_search( name, naid )

print @cgi.header "application/json"
result = JSON::generate( data )
if callback and callback =~ /^\w+$/
   result = "#{ callback }(#{ result })"
end
print result
