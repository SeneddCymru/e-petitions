document.addEventListener('DOMContentLoaded', function(event) {
  var elements = document.querySelectorAll('summary');

  for (var i = 0; i < elements.length; i++) {
    var element = elements[i];

    element.addEventListener('mousedown', function(event) {
      this.clicked = true;
    })

    element.addEventListener('focus', function(event) {
      if (this.clicked) {
        this.blur();
      }

      this.clicked = false;
    })
  }
});
