/*
 * $Id$
 */

function fuwatto_show_cinii_nrid( data ) {
  for (var i=0, entry; entry = data.entries[i]; i++) {
    entry.url.match( /\/nrid\/(\w+)$/ );
    var nrid = RegExp.$1;
    document.write('<span class="nrid" title="著者IDページ「'
		   + nrid
		   + '」に飛ぶ">'
		   + '<a href="' + entry.url + '">'
		   + '<img src="./nrid.png"/>'
		   + '</a>'
		   + '</span>');
  }
}
