Gem::Specification.new do |spec|
  spec.name          = "libvips-avif-dep"
  spec.version       = "0.1.0"
  spec.summary       = "Ensures the MSYS2 libheif package is installed so libvips can encode AVIF."
  spec.description   = "Empty gem whose only purpose is to trigger RubyInstaller's msys2_mingw_dependencies hook during `bundle install`, matching how ruby-vips installs libvips itself."
  spec.authors       = ["stanleylageweg.github.io"]
  spec.files         = ["lib/libvips_avif_dep.rb"]
  spec.require_paths = ["lib"]

  # Handled by RubyInstaller's rubygems plugin (see rubygems/defaults/operating_system.rb).
  # Runs `pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-libheif` on gem install.
  spec.metadata["msys2_mingw_dependencies"] = "libheif"
end
