function cssTimeToMs(cssTime) {
  if (typeof cssTime === 'string' || cssTime instanceof String) {
    const trimmed = cssTime.trim().toLowerCase();
    const num = parseFloat(trimmed);
    if (trimmed.endsWith('ms')) {
      return num;
    } else if (trimmed.endsWith('s')) {
      return num * 1000;
    }
  }
}

if (!CSS.supports("(interpolate-size: allow-keywords) and (transition-behavior: allow-discrete) and selector(::details-content)")) {
  document.querySelectorAll('details').forEach((el) => {
    const summary = el.querySelector('summary');
    summary.addEventListener('click', (e) => {
      // Get the animation duration
      const computedStyle = window.getComputedStyle(el);
      const durationText = computedStyle.getPropertyValue('--animatedDetails-duration-transition').trim();
      const durationMs = cssTimeToMs(durationText);
      console.log(durationMs);
      if (!durationMs) {
        return;
      }

      // We set the open state manually, to prevent instant closing
      e.preventDefault();
      
      const openTag = "animated-details--open";

      if (el.open) {
        cancelAnimationFrame(el.dataset.animatedDetailsOpeningId);

        if (el.classList.contains(openTag)) {
          // Currently open(ing), start closing
          el.classList.remove(openTag);

          // Actually close the details after a delay, to allow the closing animation to play
          el.dataset.animatedDetailsClosingId = setTimeout(() => {
            if (!el.classList.contains(openTag)) {
              el.open = false;
            }
          }, durationMs);
        } else {
          // Currently closing, start opening again
          clearTimeout(el.dataset.animatedDetailsClosingId);
          el.classList.add(openTag);
        }
      } else {
        // Currently closed, start opening
        el.open = true;

        // Wait to allow the browser to register the start state of the animation.
        el.dataset.animatedDetailsOpeningId = window.requestAnimationFrame(() => {
          if (el.open) {
            el.classList.add(openTag);
          }
        });
      }
    });
  });
}
