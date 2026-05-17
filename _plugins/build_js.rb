JS__FILES = Dir[
  "assets/js/vendor/jquery/jquery-3.6.0.js",
  "assets/js/plugins/*.js",
  "assets/js/custom/*.js",
  "assets/js/_main.js"
]

# Exclude the javascript files that we'll be minifying
Jekyll::Hooks.register :site, :post_read do |site|
  JS__FILES.each do |file_path|
    site.static_files.delete_if { |file| file.relative_path == "/#{file_path}" }
  end
end

# Minify the javascript files
Jekyll::Hooks.register :site, :post_write do |site|
  target = File.join(site.dest, "assets/js/main.min.js")

  target_mtime = File.exist?(target) ? File.mtime(target) : Time.at(0)
  needs_rebuild = JS__FILES.any? { |file| File.mtime(file) > target_mtime }
  next unless needs_rebuild

  started_at = Time.now
  Jekyll.logger.info("Javascript Minify:", "starting.")

  system(
    "npx", "uglifyjs",
    "-c",
    "--source-map",
    "-m",
    "-o", target,
    *JS__FILES
  ) or raise "JavaScript build failed"

  Jekyll.logger.info("Javascript Minify:", "done in #{(Time.now - started_at).round(2)} seconds.")
end
