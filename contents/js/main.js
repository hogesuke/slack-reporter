$(function() {
  $('a[href^=#]').click(function (e) {
    var target = $(this.hash);
    if (!target.length) return;

    var targetY = $("#main-body").scrollTop() + target.offset().top;
    $('#main-body').animate({ scrollTop: targetY }, 700, 'swing', function () {
      window.location.hash = this.hash
    });

    return false;
  });
});
