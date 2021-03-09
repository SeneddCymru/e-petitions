document.addEventListener('DOMContentLoaded', function(event) {
  'use strict';

  var meta = document.querySelector('meta[name=count_url]')
  var url = meta ? meta.content : false;
  var interval = 10000;
  var speed = 1000;
  var refresh = 50;

  var formatCount = function(count) {
    return count.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  var updateCount = function(newCount) {
    var counter = document.querySelector('.signature-count-number .count');
    var currentCount = parseFloat(counter.dataset.count);
    var loops = Math.ceil(speed / refresh);
    var index = 0;
    var increment = (newCount - currentCount) / loops;
    var timer;

    var updater = function() {
      currentCount += increment;
      index++;

      counter.textContent = formatCount(currentCount);

      if (index >= loops) {
        clearInterval(timer);
        counter.textContent = formatCount(newCount);
        counter.dataset.count = newCount
      }
    }

    if (currentCount != newCount) {
      timer = setInterval(updater, refresh);
    }
  }

  var handleError = function(event) {
    setTimeout(fetchCount, interval)
  }

  var handleResponse = function(event) {
    var xhr = event.target;

    if (xhr.status === 200) {
      var data = JSON.parse(xhr.response);
      updateCount(parseFloat(data.signature_count));
    }

    setTimeout(fetchCount, interval)
  }

  var fetchCount = function() {
    var xhr = new XMLHttpRequest();

    xhr.onload = handleResponse;
    xhr.onerror = handleError;
    xhr.open('GET', url);
    xhr.send();
  }

  if (url) {
    fetchCount();
  }
});
