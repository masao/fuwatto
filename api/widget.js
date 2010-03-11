/* $Id$ 
 * Fuwatto Search Widget
 * written by Masao Takaku
 */
var BASEURL = 'http://fuwat.to/cinii';
//var BASEURL = 'http://localhost/~masao/private/cvswork/fuwatto/cinii.rb';
function fuwatto_widget( opt ){
  var width = opt.width || 'auto';
  var height = opt.height || 'auto';
  var count = opt.count || 5;
  document.write('<div style="width:'+width+'px;height:'+height+'px;border:solid 1px gray;padding:4px;overflow:auto;"' +
		 ' id="fuwatto_result"></div>' + 
		 '<script src="'+ BASEURL + '?format=json&amp;url=' + document.location.href + '&amp;count=' + count + '&amp;callback=fuwatto_show_result" type="text/javascript"></script>');
}

function fuwatto_show_result( data ) {
  var h3 = document.createElement('h3');
  h3.appendChild( document.createTextNode("関連文献") );
  h3.setAttribute('style','margin-bottom:0;');
  document.getElementById('fuwatto_result').appendChild(h3);
  var keywords = document.createElement('div');
  keywords.setAttribute('class','fuwatto_keywords');
  keywords.setAttribute('style','text-align:right;font-size:smaller;');
  keywords.appendChild( document.createTextNode( data["q"] + "\n" ) );
  document.getElementById('fuwatto_result').appendChild(keywords);
		   
  var dl = document.createElement('dl');
  dl.setAttribute('style','margin-bottom:0;');
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
    dd_author.setAttribute('style','font-size:smaller;');
    dd_author.appendChild( document.createTextNode(entry.author) );
    dl.appendChild(dd_author);

    var dd_info = document.createElement('dd');
    dd_info.setAttribute('class','fuwatto_info');
    dd_info.setAttribute('style','font-size:smaller;');
    var span_pubname = document.createElement('span');
    span_pubname.setAttribute('class', 'fuwatto_pubname');
    span_pubname.appendChild( document.createTextNode(entry.publicationName) );
    dd_info.appendChild(span_pubname);
    dd_info.appendChild( document.createTextNode(";\n") );
    var span_pubdate = document.createElement('span');
    span_pubdate.setAttribute('class', 'fuwatto_pubdate');
    span_pubdate.appendChild( document.createTextNode(entry.publicationDate) );
    dd_info.appendChild(span_pubdate);
    dl.appendChild(dd_info);
  }
  document.getElementById('fuwatto_result').appendChild(dl);

  var footer = document.createElement('div');
  footer.setAttribute('style','text-align:right;font-size:smaller;');
  footer.innerHTML = 'Powered by <a href="' + BASEURL + '?url=' + document.location.href + '">ふわっとCiNii関連検索</a>';
  document.getElementById('fuwatto_result').appendChild(footer);
}
