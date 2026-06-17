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
require "yaml"

require "jekyll"
require "liquid"
require "vips"

module Jekyll
  module ResponsiveImage
    DEFAULT_CONFIG = {
      "default_widths" => [480, 960, 1280, 1920, 2560, 3840],
      "default_heights" => [],
      "default_formats" => ["webp", "jpg", "png"],
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
        source_match = text.to_s.strip.match(/\A(\S+)\s*(.*)/m)
        raise ArgumentError, "responsive_image tag requires a source path" if source_match.nil?

        tokens = [{ key: "source", expr: Liquid::Expression.parse(source_match[1]) }]
        source_match[2].scan(Liquid::TagAttributes) do |key, value|
          tokens << { key: key, expr: Liquid::Expression.parse(value) }
        end
        tokens
      end

      def resolve_tokens(tokens, context)
        tokens.each_with_object({}) do |token, options|
          options[token[:key]] = context.evaluate(token[:expr])
        end
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

      def get_source_path(site, source_rel, config)
        source_path = File.join(site.source, source_rel)
        raise Liquid::Error, "Image source not found: #{source_rel}" unless File.exist?(source_path)
        source_path
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

      def mime_type(format)
        case format
        when "jpg" then "image/jpeg"
        else "image/#{format}"
        end
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

      def has_alpha?(image)
        image.bands == 2 || (image.bands == 4 && image.interpretation != :cmyk) || image.bands > 4
      end

      def has_transparency?(image)
        has_alpha?(image) && image[image.bands - 1].min < 255
      end

      def add_keep_file(site, path)
        site.keep_files << path unless site.keep_files.include?(path)
      end

      def generate_image(site, source_path, source_rel, size, axis, format)
        output_path = get_output_path(site, source_rel, size, axis, format)
        rel_output_path = Pathname.new(output_path).relative_path_from(Pathname.new(site.dest)).to_s
        source_mtime = File.mtime(source_path)

        # Check if there's a marker file indicating the source image should be used for this size/format
        marker_path = "#{output_path}.use-source"
        rel_marker_path = "#{rel_output_path}.use-source"
        if File.exist?(marker_path) && File.mtime(marker_path) >= source_mtime
          add_keep_file(site, rel_marker_path)
          return source_path
        end

        # Generate the variant if it doesn't exist or is outdated
        unless File.exist?(output_path) && File.mtime(output_path) >= source_mtime
          started_at = Time.now

          FileUtils.mkdir_p(File.dirname(output_path))

          image = Vips::Image.new_from_file(source_path, access: :sequential)
          image = image.autorot if image.respond_to?(:autorot)

          source_dimension = axis.to_s == "h" ? image.height.to_i : image.width.to_i
          source_format = normalize_format(File.extname(source_path))

          source_width = image.width.to_f
          source_height = image.height.to_f
          target = Integer(size)
          scale = axis.to_s == "h" ? target / source_height : target / source_width

          resized = scale == 1.0 ? image : image.resize(scale)
          resized.write_to_file(output_path)

          # If the generated file is larger than the source, use the source instead and create a marker file to skip regeneration next time.
          if Integer(size) == source_dimension && format == source_format && File.size(source_path) <= File.size(output_path)
            File.delete(output_path)
            FileUtils.touch(marker_path)
            Jekyll.logger.info("Responsive Image:", "generated #{rel_output_path} in #{(Time.now - started_at).round(2)} seconds, but using source image because it's smaller.")
            add_keep_file(site, rel_marker_path)
            return source_path
          else
            Jekyll.logger.info("Responsive Image:", "generated #{rel_output_path} in #{(Time.now - started_at).round(2)} seconds.")
          end
        end

        add_keep_file(site, rel_output_path)
        output_path
      end

      def build_sources(site, source_path, source_rel, sizes, axis, formats)
        source_image = Vips::Image.new_from_file(source_path, access: :sequential)
        source_image = source_image.autorot if source_image.respond_to?(:autorot)
        source_dimension = axis.to_s == "h" ? source_image.height.to_i : source_image.width.to_i
        source_format = normalize_format(File.extname(source_path))

        effective_sizes = sizes.map { |s| Integer(s) }.select { |s| s < source_dimension }
        effective_sizes = (effective_sizes << source_dimension).uniq.sort

        effective_formats = formats.uniq
        if has_transparency?(source_image)
          effective_formats = formats.reject { |f| f == "jpg" }
        end

        effective_formats.each_with_object({}) do |format, groups|
          groups[format] = effective_sizes.map do |size|
            out = generate_image(site, source_path, source_rel, size, axis, format)
            image = Vips::Image.new_from_file(out, access: :sequential)
            image = image.autorot if image.respond_to?(:autorot)

            {
              path: out,
              url: public_url(site, out),
              width: image.width.to_i,
              height: image.height.to_i,
              format: format,
              size: size,
              axis: axis.to_s
            }
          end
        end
      end

      def reset_after_build(site)
        reset_registry_for(site)
      end
    end

    class ImageTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @tokens = ResponsiveImage.parse_tag_text(text)
      end

      def render(context)
        site = context.registers[:site]
        config = DEFAULT_CONFIG.merge(site.config.fetch("responsive_image", {}))
        opts = ResponsiveImage.resolve_tokens(@tokens, context)

        source_rel = opts.fetch("source")
        source_path = ResponsiveImage.get_source_path(site, source_rel, config)

        alt = opts["alt"] || ResponsiveImage.get_alt_text(site, source_rel, config)
        css_class = opts["class"].to_s.strip

        if ResponsiveImage.normalize_format(File.extname(source_path)) == "svg"
          img_attrs = [%(src="#{escape_html(ResponsiveImage.public_url(site, File.join(site.dest, source_rel)))}")]
          img_attrs << %(alt="#{escape_html(alt)}") unless alt.empty?
          img_attrs << %(class="#{escape_html(css_class)}") unless css_class.empty?
          return %(<img #{img_attrs.join(' ')}/>)
        end

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
                  end.map { |f| ResponsiveImage.normalize_format(f) }

        axis = if !widths.empty? && !heights.empty?
                 raise ArgumentError, "Use either widths=... or heights=..., not both, for #{source_rel}."
               elsif !widths.empty?
                 "w"
               else
                 "h"
               end

        sizes = widths.empty? ? heights : widths

        sources = ResponsiveImage.build_sources(site, source_path, source_rel, sizes, axis, formats)
        source_tags = sources.map do |format, source|
          srcset = source.map { |c| "#{c[:url]} #{c[:width]}w" }.join(", ")
          %(<source type="#{escape_html(ResponsiveImage.mime_type(format))}" srcset="#{escape_html(srcset)}"/>)
        end

        img_attrs = [%(src="#{escape_html(ResponsiveImage.public_url(site, File.join(site.dest, source_rel)))}")]
        img_attrs << %(alt="#{escape_html(alt)}") unless alt.empty?
        img_attrs << %(class="#{escape_html(css_class)}") unless css_class.empty?

        %(<picture>#{source_tags.join}<img #{img_attrs.join(' ')}/></picture>)
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
