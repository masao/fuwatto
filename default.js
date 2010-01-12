function submit_page_text( page )
{
  var form = document.forms.text1;
  // alert( form );
  form.innerHTML += '<input type="hidden" name="page" value="' + page + '">';
  form.submit();
}
