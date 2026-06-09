(function () {
  function setup(sidebar) {
    const header = sidebar.querySelector('.author__header');
    const body = sidebar.querySelector('.author__body');
    const main = sidebar.closest('main');
    if (!header || !body || !main) return;

    function update() {
      sidebar.style.setProperty('--author-header-height', header.offsetHeight + 'px');
      sidebar.style.setProperty('--author-body-height', body.offsetHeight + 'px');
      const bottomMargin = parseFloat(getComputedStyle(main).marginBottom) || 0;
      const available = window.innerHeight - header.offsetHeight - bottomMargin;
      sidebar.classList.toggle('is-tall', body.offsetHeight > available);
    }

    if (typeof ResizeObserver !== 'undefined') {
      const resizeObserver = new ResizeObserver(update);
      resizeObserver.observe(header);
      resizeObserver.observe(body);
    }

    // window.resize covers viewport size changes,
    // as ResizeObserver only fires when the content size changes.
    window.addEventListener('resize', update);

    update();
  }

  document.querySelectorAll('.sidebar').forEach(setup);
})();
