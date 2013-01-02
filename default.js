function submit_page_text( page )
{
  var form = document.forms.text1;
  // alert( form );
  form.innerHTML += '<input type="hidden" name="page" value="' + page + '">';
  form.submit();
}

function display_feed_as_examples( result )
{
  if (!result.error){
    var container = document.getElementById("feed");
    var htmlstr = "<h3>Examples from Google News</h3><ul>";
    for (var i = 0; i < result.feed.entries.length; i++) {
      var entry = result.feed.entries[i];
      htmlstr += '<li><a href="?url=' + encodeURIComponent( entry.link ) + '">' + entry.title + '</a> <span style="font-size:smaller;">(<a href="' + entry.link + '">original article</a>)</span></li>';
    }
    htmlstr += "</ul>";
    container.innerHTML = htmlstr;
  }
}
function display_feed_mainichi_opinion( result )
{
  if (!result.error){
    var container = document.getElementById("feed_mainichi_opinion");
    var htmlstr = "<h3>検索例: 毎日新聞/社説・オピニオン</h3><ul>";
    for (var i = 0; i < result.feed.entries.length; i++) {
      var entry = result.feed.entries[i];
      htmlstr += '<li><a href="?url=' + encodeURIComponent( entry.link ) + '">ふわっと関連検索:' + entry.title + '</a> <span style="font-size:smaller;">(<a href="' + entry.link + '">元記事</a>)</span></li>';
    }
    htmlstr += "</ul>";
    container.innerHTML = htmlstr;
  }
}
