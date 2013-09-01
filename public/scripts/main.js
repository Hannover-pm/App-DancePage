/*! App::DancePage 0.001 | (c) 2013 BURNERSK | p3rl.org/App::DancePage */
$(document).ready(function() {
  if ($('.for_epiceditor').length > 0) {
    $.getScript('/scripts/epiceditor/epiceditor.js', function() {
      $('.for_epiceditor').each(function() {
        var me = $(this);
        var editor = $('<div></div>');
        editor.attr('id', 'epiceditor_' + me.attr('id'));
        editor.attr('class', 'epiceditor');
        $(this).parent().append(editor);
        var opts = new Object();
        opts.container = editor.attr('id');
        opts.textarea = me.attr('id');
        opts.basePath = '/scripts/epiceditor/';
        opts.focusOnLoad = true;
        opts.button = new Object({
          bar: 'show'
        });
        opts.autogrow = true;
        var epiceditor = new EpicEditor(opts);
        epiceditor.load();
        me.css('visibility', 'hidden');
        me.css('position', 'absolute');
      });
    });
  }
});