require "cgi"
require "yaml"

require "jekyll"
require "liquid"
require_relative "utils"

# Require ruby-vips while capturing its startup chatter and routing it through Jekyll's logger.
pipe_r, pipe_w = IO.pipe
saved_stderr = STDERR.dup
begin
  # Point fd 2 at the pipe so libvips's C-level `g_warning()` output is captured instead of printed.
  STDERR.reopen(pipe_w)
  pipe_w.close
  require "vips"
ensure
  # Restore fd 2. This drops the last reference to the pipe's write end, so reads below hit EOF.
  STDERR.reopen(saved_stderr)
  saved_stderr.close
end

# GLib log format: "(process:PID): DOMAIN-LEVEL **: TIME: MESSAGE"
glib_log_line = /\A\([^)]+\):\s+\S+-(\w+)\s+\*\*:\s+[\d:.]+:\s+(.*)/

pipe_r.each_line do |line|
  # Expected noise: optional codec DLLs we don't ship (JPEG XL, openslide, poppler, ImageMagick).
  next if line =~ /VIPS-WARNING.*unable to load.*vips-modules/

  if (match = line.match(glib_log_line))
    # Route recognized GLib log lines through Jekyll's logger so severity coloring kicks in.
    level, message = match[1], match[2].chomp
    case level
    when "ERROR", "CRITICAL"
      Jekyll.logger.error("libvips:", message)
    when "WARNING"
      Jekyll.logger.warn("libvips:", message)
    else
      Jekyll.logger.info("libvips:", message)
    end
  else
    # Unrecognized output: pass through verbatim rather than swallow it.
    STDERR.print(line)
  end
end
pipe_r.close

module Jekyll
  module ResponsiveImage
    CONFIG = {
      widths: [480, 960, 1280, 1920, 2560, 3840],
      formats: ["avif", "webp"],
      oversample: 1.5,
      alt_map_data_file: "responsive_image_alts"
    }.freeze

    class << self
      def get_cache_key
        "_"
      end

      def get_optional_cache_key
        Utils.cache_key(CONFIG.except(:oversample, :alt_map_data_file))
      end

      def parse_extra_source_options(value)
        return [] if value.nil?
        raise ArgumentError, "Extra source definitions must be provided as an array of hashes." unless value.is_a?(Array)

        value.map do |entry|
          raise ArgumentError, "Each extra source definition must be a hash." unless entry.is_a?(Hash)

          source = entry["source"]
          raise ArgumentError, "Extra source definitions must include a source path." if source.nil? || source.to_s.strip.empty?

          entry
        end
      end

      def get_alt_text(site, source_path)
        alt_file = CONFIG[:alt_map_data_file].to_s
        data = site.data[alt_file] || site.data[alt_file.to_sym]
        if data.respond_to?(:[])
          result = data[source_path.relative_path]
          return result if result
        end

        Jekyll.logger.warn("Responsive Image:", "Missing alt text for '#{source_path.relative_path}'. Add it to _data/#{CONFIG[:alt_map_data_file]}.yml or pass alt=\"...\" in the tag.")
        ""
      end

      def mime_type(format)
        case format
        when "jpg" then "image/jpeg"
        else "image/#{format}"
        end
      end

      def has_alpha?(image)
        image.bands == 2 || (image.bands == 4 && image.interpretation != :cmyk) || image.bands > 4
      end

      def has_transparency?(image)
        has_alpha?(image) && image[image.bands - 1].min < 255
      end

      def build_sources(source_path, widths, formats)
        source_image = Vips::Image.new_from_file(source_path, access: :sequential)
        source_image = source_image.autorot if source_image.respond_to?(:autorot)
        source_width = source_image.width.to_i
        source_height = source_image.height.to_i

        max_width = [widths.max, source_width].compact.min
        effective_widths = (widths << source_width).uniq.sort
        effective_widths = effective_widths.map { |w| Integer(w) }.select { |w| w <= max_width }

        effective_formats = formats.uniq
        if has_transparency?(source_image)
          effective_formats = formats.reject { |f| f == "jpg" }
        end

        sources = {}
        generated_variants = []
        Utils.log_duration("Responsive Image:") do
          effective_formats.each do |format|
            sources[format] = effective_widths.map do |width|
              output_path = OutputFilepath.new(source_path, suffix: "-#{width}w", extension: format)

              target_width = Integer(width)
              scale = target_width.to_f / source_width
              target_height = (source_height * scale).round

              # Generate the variant if it doesn't exist or is outdated
              unless output_path.up_to_date?
                image = Vips::Image.new_from_file(source_path, access: :sequential)
                image = image.autorot if image.respond_to?(:autorot)
                image = image.resize(scale) unless scale == 1.0

                output_path.make_directory
                image.write_to_file(output_path)
                generated_variants << "#{target_width}w.#{format}"
              end

              output_path.add_keep_file
              { path: output_path, width: target_width, height: target_height, format: format }
            end
          end
          "generated #{source_path.relative_path} [#{generated_variants.join(", ")}]" if generated_variants.any?
        end

        sources
      end
    end
  end
end
