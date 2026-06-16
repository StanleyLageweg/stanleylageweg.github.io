# {% responsive_image /assets/images/mountain.jpg class="hero" %}
# {% responsive_image /assets/images/mountain.jpg widths="360,720,1080" formats="webp,jpg" class="hero" %}
# {% responsive_image /assets/images/mountain.jpg heights="300,600" formats="jpg" %}
#
# Notes:
# - Generated files are written to site.dest only; they are not copied from source.
# - `srcset` uses standard `w` descriptors, even when the image was generated from heights.

require "cgi"
require "fileutils"
require "pathname"
require "set"
require "shellwords"
require "yaml"

require "jekyll"
require "liquid"
require "vips"

module Jekyll
  module ResponsiveImage
    DEFAULT_CONFIG = {
      "default_widths" => [480, 960, 1440],
      "default_heights" => [],
      "default_formats" => ["webp", "jpg"],
      "alt_map_data_file" => "responsive_image_alts"
    }.freeze

    class << self
      def registry_for(site)
        @registries ||= {}
        @registries[site.object_id] ||= {
          generated: Set.new,
          cache: {},
          warned_missing_alt: Set.new
        }
      end

      def reset_registry_for(site)
        @registries ||= {}
        @registries[site.object_id] = {
          generated: Set.new,
          cache: {},
          warned_missing_alt: Set.new
        }
      end

      def parse_tag_text(text)
        tokens = Shellwords.split(text.to_s)
        raise ArgumentError, "responsive_image tag requires a source path" if tokens.empty?

        source = tokens.shift
        options = { "source" => source }

        tokens.each do |token|
          key, value = token.split("=", 2)
          raise ArgumentError, "Invalid option '#{token}'. Use key=\"value\"." if value.nil?
          options[key] = value
        end

        options
      end

      def parse_list(value)
        case value
        when nil
          []
        when Array
          value.flatten.map(&:to_s).map(&:strip).reject(&:empty?)
        else
          value.to_s.split(",").map(&:strip).reject(&:empty?)
        end
      end

      def parse_int_list(value)
        parse_list(value).map do |item|
          Integer(item)
        rescue ArgumentError
          raise ArgumentError, "Invalid size '#{item}'. Sizes must be integers."
        end
      end

      def source_path_for(site, source_rel, config)
        raw = source_rel.to_s
        raw = raw.sub(%r{\A/+}, "")

        candidates = []
        candidates << File.expand_path(raw, site.source)

        source_dir = config["source_dir"].to_s.strip
        unless source_dir.empty?
          candidates << File.expand_path(File.join(source_dir, raw), site.source)
        end

        candidates.find { |path| File.file?(path) } || raise(ArgumentError, "Image source not found: #{source_rel}")
      end

      def get_alt_text(site, source_rel, config)
        alt_file = config["alt_map_data_file"].to_s
        data = site.data[alt_file] || site.data[alt_file.to_sym]
        if data.respond_to?(:[])
          result = data[source_rel]
          return result if result
        end

        registry = registry_for(site)
        unless registry[:warned_missing_alt].include?(source_rel)
          registry[:warned_missing_alt] << source_rel
          Jekyll.logger.warn("Responsive Image:", "Missing alt text for '#{source_rel}'. Add it to _data/#{config["alt_map_data_file"]}.yml or pass alt=\"...\" in the tag.")
        end

        return ""
      end

      def get_output_path(site, source_rel, size, axis, format)
        path = Pathname.new(source_rel)
        basename = path.basename(path.extname)
        ext = normalize_format(format)
        size_suffix = "#{Integer(size)}#{axis}"
        File.join(site.dest, path.dirname, "#{basename}-#{size_suffix}.#{ext}")
      end

      def normalize_format(format)
        # Remove the '.' at the start of the string
        ext = format.to_s.downcase.sub(%r{\A\.}, "")
        ext = "jpg" if ext == "jpeg"
        ext
      end

      def public_url(site, path)
        dest = File.expand_path(site.dest)
        rel = Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(dest)).to_s.tr(File::SEPARATOR, "/")
        baseurl = site.config["baseurl"].to_s
        baseurl = "" if baseurl == "/"
        baseurl = "/#{baseurl}" unless baseurl.empty? || baseurl.start_with?("/")
        baseurl = baseurl.chomp("/")
        url = "#{baseurl}/#{rel}".gsub(%r{/+}, "/")
        url.empty? ? "/#{rel}" : url
      end

      def maybe_flatten_for_jpeg(image)
        image.flatten(background: [255, 255, 255])
      rescue StandardError
        image
      end

      def generate_variant(site, source_path, source_rel, size, axis, format)
        output_path = get_output_path(site, source_rel, size, axis, format)
        rel_output_path = Pathname.new(output_path).relative_path_from(Pathname.new(site.dest)).to_s
        source_mtime = File.mtime(source_path)

        # Generate the variant if it doesn't exist or is outdated
        unless File.exist?(output_path) && File.mtime(output_path) >= source_mtime
          started_at = Time.now

          FileUtils.mkdir_p(File.dirname(output_path))

          image = Vips::Image.new_from_file(source_path, access: :sequential)
          image = image.autorot if image.respond_to?(:autorot)

          source_width = image.width.to_f
          source_height = image.height.to_f
          target = Integer(size)
          scale = axis.to_s == "h" ? target / source_height : target / source_width

          resized = scale == 1.0 ? image : image.resize(scale)
          resized = maybe_flatten_for_jpeg(resized) if %w[jpg jpeg].include?(normalize_format(format))

          resized.write_to_file(output_path)
          Jekyll.logger.info("Responsive Image:", "generated #{rel_output_path} in #{(Time.now - started_at).round(2)} seconds.")
        end

        unless site.keep_files.include?(rel_output_path)
          site.keep_files << rel_output_path
        end

        output_path
      end

      def build_candidates(site, source_path, source_rel, sizes, axis, formats)
        candidates = []

        sizes.each do |size|
          formats.each do |format|
            out = generate_variant(site, source_path, source_rel, size, axis, format)
            image = Vips::Image.new_from_file(out, access: :sequential)
            image = image.autorot if image.respond_to?(:autorot)

            candidates << {
              path: out,
              url: public_url(site, out),
              width: image.width.to_i,
              height: image.height.to_i,
              format: normalize_format(format),
              size: size,
              axis: axis.to_s
            }
          end
        end

        candidates
      end

      def reset_after_build(site)
        reset_registry_for(site)
      end
    end

    class ImageTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @raw = text.to_s
      end

      def render(context)
        site = context.registers[:site]
        config = DEFAULT_CONFIG.merge(site.config.fetch("responsive_image", {}))
        opts = ResponsiveImage.parse_tag_text(@raw)

        source_rel = opts.fetch("source")
        source_path = ResponsiveImage.source_path_for(site, source_rel, config)

        widths = if opts.key?("widths")
                   ResponsiveImage.parse_int_list(opts["widths"])
                 else
                   ResponsiveImage.parse_int_list(config["default_widths"])
                 end

        heights = if opts.key?("heights")
                    ResponsiveImage.parse_int_list(opts["heights"])
                  else
                    ResponsiveImage.parse_int_list(config["default_heights"])
                  end

        formats = if opts.key?("formats")
                    ResponsiveImage.parse_list(opts["formats"])
                  else
                    ResponsiveImage.parse_list(config["default_formats"])
                  end

        raise ArgumentError, "No image sizes configured for #{source_rel}. Provide widths=... or heights=..., or set responsive_image.default_widths/default_heights." if widths.empty? && heights.empty?
        raise ArgumentError, "No output formats configured for #{source_rel}. Provide formats=... or set responsive_image.default_formats." if formats.empty?

        axis = if !widths.empty? && !heights.empty?
                 raise ArgumentError, "Use either widths=... or heights=..., not both, for #{source_rel}."
               elsif !widths.empty?
                 "w"
               else
                 "h"
               end

        sizes = widths.empty? ? heights : widths
        alt = opts["alt"] || ResponsiveImage.get_alt_text(site, source_rel, config)

        css_class = opts["class"].to_s.strip

        candidates = ResponsiveImage.build_candidates(site, source_path, source_rel, sizes, axis, formats)
        raise ArgumentError, "Image generation produced no files for #{source_rel}." if candidates.empty?

        primary_format = ResponsiveImage.normalize_format(formats.first)
        primary_candidates = candidates.select { |c| c[:format] == primary_format }
        primary_candidates = candidates if primary_candidates.empty?

        primary_candidates = primary_candidates.uniq { |c| c[:width] }
        primary_candidates = primary_candidates.sort_by { |c| c[:width] }

        src_candidate = primary_candidates.max_by { |c| c[:width] } || candidates.max_by { |c| c[:width] }
        srcset = primary_candidates.map do |candidate|
          "#{candidate[:url]} #{candidate[:width]}w"
        end.join(", ")

        attrs = []
        attrs << %(srcset="#{escape_html(srcset)}") unless srcset.empty?
        attrs << %(src="#{escape_html(src_candidate[:url])}")
        attrs << %(alt="#{escape_html(alt)}") unless alt.empty?
        attrs << %(class="#{escape_html(css_class)}") unless css_class.empty?

        %(<img #{attrs.join(' ')}/>)
      end

      private

      def escape_html(value)
        CGI.escapeHTML(value.to_s)
      end
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  Jekyll::ResponsiveImage.reset_after_build(site)
end

Liquid::Template.register_tag("responsive_image", Jekyll::ResponsiveImage::ImageTag)
