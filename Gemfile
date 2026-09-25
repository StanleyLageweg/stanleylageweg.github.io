source "https://rubygems.org"

ruby file: ".ruby-version"

gem "jekyll", ">= 4.4", "< 5.0"
gem "jekyll-sitemap", "~> 1.3"
gem "kramdown-math-katex", "~> 1.0"

gem "bigdecimal"
gem "bundler"
gem "launchy"
gem "ruby-prof", group: :jekyll_plugins, require: ["ruby-prof", "./_plugins/hooks/rubyprof"]
gem "ruby-vips"
gem "wdm", ">= 0.1.0", :platforms => [:windows]

# Local gem whose only purpose is to install the MSYS2 libheif package (via RubyInstaller's
# rubygems plugin) so that libvips can encode AVIF. Only relevant on Windows/RubyInstaller.
platforms :windows do
  gem "libvips-avif-dep", path: "vendor/libvips-avif-dep"
end
