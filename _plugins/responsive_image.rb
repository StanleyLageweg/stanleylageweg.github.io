# frozen_string_literal: true

# Place this file in your Jekyll site's `_plugins/` directory.
#
# Example `_config.yml`:
#
# responsive_image:
#   output_dir: assets/generated/images
#   default_widths: [480, 960, 1440]
#   default_formats: [webp, jpg]
#   alt_map_data_file: responsive_image_alts
#   warn_on_missing_alt: true
#
# Example `_data/responsive_image_alts.yml`:
#
# mountain.jpg: "Snowy mountain at sunrise"
# gallery/forest.jpg: "Forest path after rain"
#
# Tag usage:
#
# {% responsive_image assets/images/mountain.jpg class="hero" %}
# {% responsive_image assets/images/mountain.jpg widths="360,720,1080" formats="webp,jpg" class="hero" %}
# {% responsive_image assets/images/mountain.jpg heights="300,600" formats="jpg" %}
#
# Notes:
# - Generated files are written to site.dest only; they are not copied from source.
# - Stale generated files in the output_dir are removed after each build.
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
      "output_dir" => "assets/generated/images",
      "default_widths" => [],
      "default_heights" => [],
      "default_formats" => ["webp", "jpg"],
      "alt_map_data_file" => "responsive_image_alts",
      "warn_on_missing_alt" => true
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

      def config_for(site)
        site_cfg = site.config.fetch("responsive_image", {}) || {}
        DEFAULT_CONFIG.merge(site_cfg)
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

      def alt_text_for(site, source_rel, config)
        alt_file = config["alt_map_data_file"].to_s
        data = site.data[alt_file] || site.data[alt_file.to_sym]
        return nil unless data.respond_to?(:[])

        rel = source_rel.to_s.sub(%r{\A/+}, "")
        base = File.basename(rel)

        data[rel] || data[base] || data[rel.to_sym] || data[base.to_sym]
      end

      def output_root(site, config)
        File.expand_path(config["output_dir"].to_s, site.dest)
      end

      def output_path_for(site, config, source_rel, size, axis, format)
        rel = source_rel.to_s.sub(%r{\A/+}, "")
        rel_path = Pathname.new(rel)
        dir = rel_path.dirname.to_s
        dir = "" if dir == "."

        basename = rel_path.basename(rel_path.extname).to_s
        ext = normalize_format(format)
        size_suffix = "#{Integer(size)}#{axis}"

        File.join(output_root(site, config), dir, "#{basename}--#{size_suffix}.#{ext}")
      end

      def normalize_format(format)
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

      def warn_missing_alt(site, source_rel, config)
        return unless config["warn_on_missing_alt"]

        key = source_rel.to_s.sub(%r{\A/+}, "")
        registry = registry_for(site)
        return if registry[:warned_missing_alt].include?(key)

        registry[:warned_missing_alt] << key
        Jekyll.logger.warn("responsive_image", "Missing alt text for '#{key}'. Add it to _data/#{config["alt_map_data_file"]}.yml or pass alt=\"...\" in the tag.")
      end

      def maybe_flatten_for_jpeg(image)
        image.flatten(background: [255, 255, 255])
      rescue StandardError
        image
      end

      def generate_variant(site, config, source_path, source_rel, size, axis, format)
        output_path = output_path_for(site, config, source_rel, size, axis, format)
        source_mtime = File.mtime(source_path)

        if File.exist?(output_path) && File.mtime(output_path) >= source_mtime
          registry_for(site)[:generated] << File.expand_path(output_path)
          return output_path
        end

        FileUtils.mkdir_p(File.dirname(output_path))

        cache_key = [
          File.expand_path(source_path),
          source_mtime.to_i,
          Integer(size),
          axis.to_s,
          normalize_format(format)
        ]

        registry = registry_for(site)
        if registry[:cache].key?(cache_key) && File.exist?(output_path)
          registry[:generated] << File.expand_path(output_path)
          return output_path
        end

        image = Vips::Image.new_from_file(source_path, access: :sequential)
        image = image.autorot if image.respond_to?(:autorot)

        source_width = image.width.to_f
        source_height = image.height.to_f
        target = Integer(size)
        scale = axis.to_s == "h" ? target / source_height : target / source_width

        resized = scale == 1.0 ? image : image.resize(scale)
        resized = maybe_flatten_for_jpeg(resized) if %w[jpg jpeg].include?(normalize_format(format))

        resized.write_to_file(output_path)
        registry[:cache][cache_key] = output_path
        registry[:generated] << File.expand_path(output_path)
        output_path
      end

      def build_candidates(site, config, source_path, source_rel, sizes, axis, formats)
        candidates = []

        sizes.each do |size|
          formats.each do |format|
            out = generate_variant(site, config, source_path, source_rel, size, axis, format)
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

      def cleanup_generated_files(site)
        config = config_for(site)
        root = output_root(site, config)
        return unless Dir.exist?(root)

        keep = registry_for(site)[:generated].map { |p| File.expand_path(p) }.to_set

        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).each do |path|
          next if [".", ".."].include?(File.basename(path))
          next if path == root
          next if File.directory?(path)

          File.delete(path) unless keep.include?(File.expand_path(path))
        end

        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH)
           .select { |path| File.directory?(path) }
           .sort_by { |path| -path.length }
           .each do |path|
          next if path == root

          begin
            Dir.rmdir(path)
          rescue Errno::ENOTEMPTY, Errno::ENOENT, Errno::EEXIST
            # keep directory if it still contains files
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
        @raw = text.to_s
      end

      def render(context)
        site = context.registers[:site]
        config = ResponsiveImage.config_for(site)
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
        alt = opts["alt"] || ResponsiveImage.alt_text_for(site, source_rel, config)
        ResponsiveImage.warn_missing_alt(site, source_rel, config) if alt.nil?
        alt = "" if alt.nil?

        css_class = opts["class"].to_s.strip

        candidates = ResponsiveImage.build_candidates(site, config, source_path, source_rel, sizes, axis, formats)
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

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::ResponsiveImage.cleanup_generated_files(site)
end

Liquid::Template.register_tag("responsive_image", Jekyll::ResponsiveImage::ImageTag)
