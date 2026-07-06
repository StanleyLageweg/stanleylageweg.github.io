source "https://rubygems.org"

ruby file: ".ruby-version"

gem "jekyll", ">= 3.7", "< 5.0"
gem "jekyll-sass-converter", "~> 2.2" # Locked to 2.2, as newer versions cause deprecation warnings. The theme would need to be refactored to support Dart Sass.
gem "jekyll-sitemap", "~> 1.3"
gem "kramdown-math-katex", "~> 1.0"

gem "bigdecimal"
gem "bundler"
gem "ruby-vips"
gem "wdm", ">= 0.1.0"

# Local gem whose only purpose is to install the MSYS2 libheif package (via RubyInstaller's
# rubygems plugin) so that libvips can encode AVIF. Only relevant on Windows/RubyInstaller.
platforms :windows do
  gem "libvips-avif-dep", path: "vendor/libvips-avif-dep"
end
