[![Jekyll](https://img.shields.io/badge/jekyll-%3E%3D%203.7-blue.svg)](https://jekyllrb.com/)

## Development Setup

Download the prerequisites, as per the [Jekyll documentation](https://jekyllrb.com/docs/installation/#requirements).  
For Windows, install [Ruby+Devkit](https://rubyinstaller.org/downloads/), making sure to run the `ridk install` step to install MSYS2 and the MINGW development toolchain.

In the cloned repo, run `npm install` and `bundle install`.

Install [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer).

To test the site, run `bundle exec jekyll build --watch` and click `Go Live` in the bottom right corner to start the live server.
As modifications are made to the site's source, the site will be rebuild and the browser will refresh on its own.  
(`bundle exec jekyll serve --livereload` should work the same, but has issues with loading videos.)

## Credits

### Jekyll theme

- [Minimal Mistakes](https://github.com/mmistakes/minimal-mistakes) - [Michael Rose](https://mademistakes.com)

### Icons + Demo Images:

- [The Noun Project](https://thenounproject.com) - Garrett Knoll, Arthur Shlain, and [tracy tam](https://thenounproject.com/tracytam)
- [Font Awesome](http://fontawesome.io/)
- [Unsplash](https://unsplash.com/)

### Other:

- [Jekyll](http://jekyllrb.com/)
- [jQuery](http://jquery.com/)
- [Magnific Popup](http://dimsemenov.com/plugins/magnific-popup/)
- [FitVids.JS](http://fitvidsjs.com/)
- [GreedyNav.js](https://github.com/lukejacksonn/GreedyNav)
- [Smooth Scroll](https://github.com/cferdinandi/smooth-scroll)
- [Gumshoe](https://github.com/cferdinandi/gumshoe)
- [jQuery throttle / debounce](http://benalman.com/projects/jquery-throttle-debounce-plugin/)
- [Clipboard.js](https://clipboardjs.com)

## License

Code in this repository is licensed under the [MIT License](https://github.com/StanleyLageweg/stanleylageweg.github.io/blob/master/LICENSE).  
Portfolio materials (e.g., images, project content) may be owned by third parties. See the [NOTICE](https://github.com/StanleyLageweg/stanleylageweg.github.io/blob/master/NOTICE.md) file for details.
