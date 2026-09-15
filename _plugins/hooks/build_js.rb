module Jekyll
  module BuildJs

    module_function

    def js_files
      Dir[
        "assets/js/vendor/jquery/jquery-3.6.0.js",
        "assets/js/plugins/*.js",
        "assets/js/custom/*.js",
        "assets/js/_main.js"
      ]
    end

    # Exclude the javascript files that we'll be minifying
    def exclude_source_files(site)
      js_files.each do |file_path|
        site.static_files.delete_if { |file| file.relative_path == "/#{file_path}" }
      end
    end

    # Minify the javascript files
    def build(site)
      target = "assets/js/main.min.js"
      target_map = "assets/js/main.min.js.map"

      target_file = File.join(site.dest, target)
      target_map_file = File.join(site.dest, target_map)
      target_mtime = File.exist?(target_file) ? File.mtime(target_file) : Time.at(0)
      target_map_mtime = File.exist?(target_map_file) ? File.mtime(target_map_file) : Time.at(0)
      source_files = js_files
      previous_source_files = if File.exist?(target_map_file)
        begin
          JSON.parse(File.read(target_map_file)).fetch("sources", [])
        rescue JSON::ParserError, KeyError
          []
        end
      else
        []
      end
      needs_rebuild = source_files.sort != previous_source_files.sort ||
        source_files.any? { |file| File.mtime(file) > [target_mtime, target_map_mtime].min }

      if needs_rebuild
        Utils.log_duration("Javascript Minify:") do
          FileUtils.mkdir_p(File.dirname(target_file))

          stdout, stderr, status = Utils.fast_npx(
            "uglifyjs",
            "-c",
            "--source-map",
            "-m",
            "-o", target_file,
            *source_files
          )
          
          raise "JavaScript build failed: #{stderr.strip}" unless status.success?

          "finished"
        end
      else
        Jekyll.logger.info("Javascript Minify:", "skipped, no changes detected.")
      end

      [target, target_map].each do |file|
        unless site.keep_files.include?(file)
          site.keep_files << file
        end
      end
    end
  end
end
