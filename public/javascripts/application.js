$().ready(function() {
  if (field = $('input[type=text], input[type=email]').first()) { field.focus(); }
  $("#credentials_form").validate();
});
