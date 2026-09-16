module Jekyll
  module OptimizeSVG
    module_function

    def run(site)
      Utils.log_duration("SVG optimization:") do
        files = Dir.glob("#{site.dest}/**/*.svg").select { |file| File.file?(file) }
        stdout, stderr, status = Utils.fast_npx('svgo', *files, '-q')
        raise "SVGO failed: #{stderr.strip}" unless status.success?
        "optimized #{files.count} SVG#{'s' if files.count != 1}"
      end
    end
  end
end
