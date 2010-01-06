function submit_page_text( page )
{
  var form = document.forms.text;
  alert( form );
  form.action = form.action + '?page=' + page;
  form.submit();
}
