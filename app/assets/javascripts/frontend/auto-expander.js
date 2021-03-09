document.addEventListener('DOMContentLoaded', function(event) {
  'use strict';

  var updateHeight = function() {
    this.style.minHeight = this.initialScrollHeight;
    this.style.minHeight = this.scrollHeight + 'px';
  }

  var textareas = document.querySelectorAll('textarea');

  for (var i = 0; i < textareas.length; i++) {
    var textarea = textareas[i];

    textarea.initialScrollHeight = textarea.style.minHeight;

    updateHeight.apply(textarea);

    textarea.addEventListener('change', updateHeight);
    textarea.addEventListener('keyup', updateHeight);
    textarea.addEventListener('paste', updateHeight);
  }
});
