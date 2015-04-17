function detectScroll() {
  function findStartingPosition(scroller_frame) {
    scroller_panel = scroller_frame.find('.scroller-panel');

    frame_width = scroller_frame.width();
    panel_width = scroller_panel.width();

    if ( frame_width + 1 < panel_width ) {
      scroller_frame.addClass("panel-scrolled-left");
      console.log('scroller class added');
    } else {
      scroller_frame.removeClass("panel-scrolled-right");
      scroller_frame.removeClass("panel-scrolled-left");
      scroller_frame.removeClass("panel-scrolled-middle");
    }
  }

  function setScrollWatcher(scroller_frame) {
    scroller_panel = scroller_frame.find('.scroller-panel');
    frame_width = scroller_frame.width();
    panel_width = scroller_panel.width();

    scroller_frame.scroll(function() {
      scroller_frame = $(this);
      scroller_panel = scroller_frame.find('.scroller-panel');

      frame_width = scroller_frame.width();
      panel_width = scroller_panel.width();

      if (scroller_frame.scrollLeft() === 0 ){
        console.log("left");
        scroller_frame.addClass("panel-scrolled-left");
        scroller_frame.removeClass("panel-scrolled-right");
        scroller_frame.removeClass("panel-scrolled-middle");
      } else if (scroller_frame.scrollLeft() + frame_width + 2 > panel_width ) {
        console.log("right");
        scroller_frame.addClass("panel-scrolled-right");
        scroller_frame.removeClass("panel-scrolled-left");
        scroller_frame.removeClass("panel-scrolled-middle");
      } else {
        scroller_frame.addClass("panel-scrolled-middle");
        scroller_frame.removeClass("panel-scrolled-right");
        scroller_frame.removeClass("panel-scrolled-left");
        console.log("middle");
      }
    });
  }

  if ($('.scroller-frame') && $('.scroller-panel')) {
    console.log("Scroller elements present");

    scroller_frame = $('#data-table .scroller-frame');

    findStartingPosition(scroller_frame);
    setScrollWatcher(scroller_frame);

    tab_links = [];
    tab_links = $('#data-table .nav-tabs a');

    tab_links.each(function() {
      $(this).click(function () {
        active_tab = $($(this).attr('href'));

        scroller_frame = active_tab.find('.scroller-frame');

        setScrollWatcher(scroller_frame);

        // This needs to wait until the tab is active
        findStartingPosition(scroller_frame);
      });
    });
  }
}
