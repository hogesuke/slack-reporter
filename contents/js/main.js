$(function() {
  $('a[href^=#]').click(function (e) {
    var hash = this.hash;
    var target = $(hash);

    if (!target.length) return;

    var $mainBody = $("#main-body");
    var targetY = $mainBody.scrollTop() + target.offset().top;
    $mainBody.animate({ scrollTop: targetY }, 'slow', 'swing', function () {
      window.location.hash = hash;
    });

    return false;
  });
});
