// $Id$

var PREVIEW_BASEURL = 'http://fuwat.to/';
function preview_fuwatto()
{
  form = document.forms[0];
  var url = "http://www.asahi.com/paper/editorial.html";
  var count = form.count.value;
  var width = form.width.value;
  var height = form.height.value;
  var title = form.title.value;
  var database = form.database.value;
  document.getElementById( 'preview' ).innerHTML = '';
  var div = document.createElement( "div" );
  div.style.cssText = 'width:'+width+'px;height:'+height+'px;border:solid 1px gray;padding:4px;overflow:auto;';
  div.setAttribute( "id", "fuwatto_result" );
  var h3 = document.createElement( "h3" );
  h3.style.cssText = "margin-bottom:0px";
  h3.appendChild( document.createTextNode( title ) );
  div.appendChild( h3 );

  var script = document.createElement( "script" );
  script.setAttribute( "src", PREVIEW_BASEURL + database + '?format=json;url=' + url + ';count=' + count + ';callback=fuwatto_show_result' );
  script.setAttribute( "type", "text/javascript" );
  script.setAttribute( "defer", "defer" );

  div.appendChild( script );
  document.getElementById( 'preview' ).appendChild( div );
}
