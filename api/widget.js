/* $Id$ 
 * Fuwatto Search Widget
 * written by Masao Takaku
 */
var BASEURL = 'https://fuwat.to/';
//var BASEURL = 'http://localhost/~masao/private/cvswork/fuwatto/cinii.rb';
function fuwatto_widget( opt ){
  var url = opt.url || document.location.href;
  var database = opt.database || 'cinii';
  var width = opt.width || 'auto';
  var height = opt.height || 'auto';
  var count = opt.count || 3;
  var title = opt.title || "関連文献";
  document.write('<div style="width:'+width+';height:'+height+';border:solid 1px gray;padding:4px;overflow:auto;" id="fuwatto_result">' +
		 '<h3 style="margin:0px">' + title + '</h3></div>' + 
		 '<script src="'+ BASEURL + database + '?format=json;url=' + url + ';count=' + count + ';callback=fuwatto_show_result" type="text/javascript"></script>');
}

function fuwatto_show_result( data ) {
  var keywords = document.createElement('div');
  keywords.setAttribute('class','fuwatto_keywords');
  keywords.style.cssText = 'text-align:right;font-size:smaller';
  keywords.appendChild( document.createTextNode( data.q + "\n" ) );
  document.getElementById('fuwatto_result').appendChild(keywords);
		   
  var dl = document.createElement('dl');
  dl.style.cssText = 'margin:2px 0px;';
  for (var i=0, entry; entry = data.entries[i]; i++) {
    var dt = document.createElement('dt');
    dt.setAttribute('class','fuwatto_title');
    var a = document.createElement('a');
    a.setAttribute('href', entry.url);
    a.setAttribute('target', "_blank");
    a.appendChild(document.createTextNode(entry.title));
    dt.appendChild(a);
    dl.appendChild(dt);

    var dd_author = document.createElement('dd');
    dd_author.setAttribute('class','fuwatto_author');
    dd_author.style.cssText = 'font-size:smaller;';
    dd_author.appendChild( document.createTextNode(entry.author) );
    dl.appendChild(dd_author);

    var dd_info = document.createElement('dd');
    dd_info.setAttribute('class','fuwatto_info');
    dd_info.style.cssText = 'font-size:smaller;';
    var span_pubname = document.createElement('span');
    span_pubname.setAttribute('class', 'fuwatto_pubname');
    if ( entry.publicationName ) {
      span_pubname.appendChild( document.createTextNode(entry.publicationName) );
      dd_info.appendChild(span_pubname);
      dd_info.appendChild( document.createTextNode(";\n") );
    }
    var span_pubdate = document.createElement('span');
    span_pubdate.setAttribute('class', 'fuwatto_pubdate');
    if ( entry.publicationDate ) {
      span_pubdate.appendChild( document.createTextNode(entry.publicationDate) );
      dd_info.appendChild(span_pubdate);
    }
    dl.appendChild(dd_info);
  }
  document.getElementById('fuwatto_result').appendChild(dl);

  var footer = document.createElement('div');
  footer.style.cssText = 'text-align:right;font-size:smaller;';
  footer.innerHTML = 'Powered by <a href="' + BASEURL + data.database + '?url=' + document.location.href + '">ふわっと' + data.database.substr(0,1).toUpperCase() + data.database.substr(1) + '関連検索</a>';
  document.getElementById('fuwatto_result').appendChild(footer);
}
