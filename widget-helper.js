// $Id$

var PREVIEW_BASEURL = 'http://fuwat.to/';
function preview_fuwatto()
{
  // Build a preview format:
  var form = document.forms[0];
  var url = "http://www.asahi.com/paper/editorial.html";
  var count = form.count.value;
  var width = form.width.value;
  var height = form.height.value;
  var title = form.title.value;
  var database = form.database.value;
  document.getElementById( 'preview' ).innerHTML = '';
  var div = document.createElement( "div" );
  div.style.cssText = 'width:'+width+';height:'+height+';border:solid 1px gray;padding:4px;overflow:auto;';
  div.setAttribute( "id", "fuwatto_result" );
  var h3 = document.createElement( "h3" );
  h3.style.cssText = "margin:0px";
  h3.appendChild( document.createTextNode( title ) );
  div.appendChild( h3 );
  document.getElementById( 'preview' ).appendChild( div );

  var script = document.createElement( "script" );
  script.setAttribute( "src", PREVIEW_BASEURL + database + '?format=json;url=' + url + ';count=' + count + ';callback=fuwatto_show_result' );
  script.setAttribute( "type", "text/javascript" );
  script.setAttribute( "defer", "defer" );
  document.getElementById( 'preview' ).appendChild( script );

  // Construct a HTML snippet for Fuwatto Web Widget:
  var params = [];
  if (database && database != "cinii") {
    params.push( 'database : "' + database + '"' );
  }
  if (count && count != 3) {
    params.push( 'count : ' + count );
  }
  if (title && title != "関連文献") {
    params.push( 'title : "' + title + '"' );
  }
  if (width && width != "auto") {
    params.push( 'width : ' + width );
  }
  if (height && height != "auto") {
    params.push( 'height : ' + height );
  }
  form = document.forms[1];
  form.html.value = '<script src="http://fuwat.to/api/widget.js" type="text/javascript" charset="utf-8"></script>' + "\n" +
		    '<script type="text/javascript">' + "\n" + 
		    "fuwatto_widget({\n  " +
		    params.join( ",\n  " ) +
		    "\n});</script>";
}
