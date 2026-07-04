# Excludes unused files from the watched asset folders, so they don't get
# copied into the _site output directory.
#
# A file is considered "used" if its relative path appears in the rendered
# output of any page or document, or in any additional built file listed in
# ADDITIONAL_HAYSTACK_FILES. Any asset that isn't referenced anywhere is removed from
# the site's static files list after rendering, so it never gets written.

module Jekyll
  module ExcludeUnusedAssets
    # Directories whose static files should be checked for usage.
    WATCHED_DIRS = [
      "/assets/files",
      "/assets/images",
      "/assets/portfolio",
    ].freeze

    # Files whose content should be searched for asset references
    # in addition to the rendered pages and documents.
    ADDITIONAL_HAYSTACK_FILES = [
      "assets/js/main.min.js",
    ].freeze

    module_function

    # Builds a single string containing the contents of every rendered page/document output,
    # plus the content of every additional file that should be searched for asset references.
    def build_haystack(site)
      parts = []

      (site.pages + site.documents).each do |file|
        parts << file.output.to_s if file.output
      end

      ADDITIONAL_HAYSTACK_FILES.each do |relative|
        path = File.join(site.dest, relative)
        parts << File.read(path) if File.exist?(path)
      end

      parts.join("\n")
    end

    # Returns every static file located under one of the WATCHED_DIRS.
    def get_watched_files(site)
      site.static_files.select do |file|
        relative_path = file.relative_path.to_s
        WATCHED_DIRS.any? { |dir| relative_path.start_with?("#{dir}/") }
      end
    end

    # Returns true if file's relative path appears in the haystack.
    # Uses a negative lookahead so partial matches don't count as a reference.
    def is_used?(file, haystack)
      path = file.relative_path.to_s.sub(%r{\A/}, "")
      pattern = /#{Regexp.escape(path)}(?![\w.\-])/
      haystack.match?(pattern)
    end

    # Removes every watched file that isn't referenced anywhere in the site's rendered output,
    # so those files never get copied to the destination.
    def run(site)
      started_at = Time.now
      haystack = build_haystack(site)

      unused = get_watched_files(site).reject { |file| is_used?(file, haystack) }
      unused.each { |file| site.static_files.delete(file) }

      elapsed = (Time.now - started_at).round(2)
      if unused.any?
        Jekyll.logger.info(
          "Unused Assets:",
          "excluded #{unused.length} unused file(s) in #{elapsed} seconds:"
        )
      else
        Jekyll.logger.info(
          "Unused Assets:",
          "no unused files found (checked in #{elapsed} seconds)."
        )
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll::ExcludeUnusedAssets.run(site)
end
