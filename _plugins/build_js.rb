JS_FILES = Dir[
  "assets/js/vendor/jquery/jquery-3.6.0.js",
  "assets/js/plugins/*.js",
  "assets/js/custom/*.js",
  "assets/js/_main.js"
]

# Exclude the javascript files that we'll be minifying
Jekyll::Hooks.register :site, :post_read do |site|
  JS_FILES.each do |file_path|
    site.static_files.delete_if { |file| file.relative_path == "/#{file_path}" }
  end
end

# Minify the javascript files
Jekyll::Hooks.register :site, :pre_render do |site|
  target = "assets/js/main.min.js"
  target_map = "assets/js/main.min.js.map"

  target_file = File.join(site.dest, target)
  target_map_file = File.join(site.dest, target_map)
  target_mtime = File.exist?(target_file) ? File.mtime(target_file) : Time.at(0)
  target_map_mtime = File.exist?(target_map_file) ? File.mtime(target_map_file) : Time.at(0)
  needs_rebuild = JS_FILES.any? { |file| File.mtime(file) > [target_mtime, target_map_mtime].min }

  if needs_rebuild
    started_at = Time.now
    Jekyll.logger.info("Javascript Minify:", "starting.")

    FileUtils.mkdir_p(File.dirname(target_file))

    system(
      "npx", "uglifyjs",
      "-c",
      "--source-map",
      "-m",
      "-o", target_file,
      *JS_FILES
    ) or raise "JavaScript build failed"

    Jekyll.logger.info("Javascript Minify:", "done in #{(Time.now - started_at).round(2)} seconds.")
  else
    Jekyll.logger.info("Javascript Minify:", "skipped, no changes detected.")
  end

  [target, target_map].each do |file|
    unless site.keep_files.include?(file)
      site.keep_files << file
    end
  end
end
