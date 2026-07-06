# Logs the total size of the output directory after every build.

module Jekyll
  module LogOutputSize
    SIZE_WARNING_THRESHOLD = 1024 * 1024 * 1024 # 1 GB in bytes

    module_function

    def format_size(bytes)
      units = %w[B KB MB GB TB]
      return "0 #{units[0]}" if bytes.zero?
      exp = [Math.log(bytes, 1024).to_i, units.length - 1].min
      value = (bytes.to_f / (1024 ** exp))

      # If the displayed value would read as >= 1000, bump to the next unit
      # so "1008.08 MB" becomes "0.98 GB" instead.
      if value.round(2) >= 1000 && exp < units.length - 1
        exp += 1
        value = (bytes.to_f / (1024 ** exp))
      end

      "#{value.round(2)} #{units[exp]}"
    end

    def directory_size(path)
      Dir.glob(File.join(path, '**', '*'), File::FNM_DOTMATCH)
        .reject { |f| File.directory?(f) }
        .sum { |f| File.size(f) }
    end

    def run(site)
      total_bytes = directory_size(site.dest)
      formatted = format_size(total_bytes)

      if total_bytes > SIZE_WARNING_THRESHOLD
        message = "#{formatted} exceeds #{format_size(SIZE_WARNING_THRESHOLD)} threshold."
        if Jekyll.env == "production"
          raise "Output Size: #{message}"
        else
          Jekyll.logger.warn("Output Size:", message)
        end
      else
        Jekyll.logger.info("Output Size:", formatted)
      end
    end
  end
end
