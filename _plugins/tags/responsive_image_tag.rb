# {% responsive_image "/assets/images/mountain.jpg" class="hero" %}
# {% responsive_image "/assets/images/mountain.jpg" widths="360,720,1080" formats="webp,jpg" class="hero" %}
# {% responsive_image "/assets/images/icon.png" widths="64,128" sizes="2em" %}

require_relative "../responsive_image"
require_relative "../utils"

module Jekyll
  module ResponsiveImage
    class ImageTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @tokens = Utils.parse_attributes(text, default_attributes: ["source"])
      end

      def render(context)
        site = context.registers[:site]
        config = ResponsiveImage.config_for(site)
        opts = Utils.resolve_attributes(@tokens, context)

        source_path = Filepath.new(site, opts.fetch("source"))
        source_format = source_path.extension(normalize: true)

        alt = opts["alt"] || ResponsiveImage.get_alt_text(site, source_path, config)
        sizes_attr = opts["sizes"]
        sizes_height = opts["sizes_height"]
        raise ArgumentError, "Use either sizes=... or sizes_height=..., not both, for #{source_path.relative_path}." if sizes_attr && sizes_height

        source_width = nil
        source_height = nil
        if source_format != "svg"
          source_image = Vips::Image.new_from_file(source_path, access: :sequential)
          source_image = source_image.autorot if source_image.respond_to?(:autorot)
          source_width = source_image.width.to_i
          source_height = source_image.height.to_i
          unless ResponsiveImage.has_transparency?(source_image)
            opts["class"] = [opts["class"], "opaque"].compact.reject(&:empty?).join(" ")
          end
        end

        if sizes_height && source_width
          aspect_ratio = (source_width.to_f / source_height.to_f).round(4)
          sizes_attr = aspect_ratio == 1.0 ? sizes_height : "calc(#{sizes_height} * #{aspect_ratio})"
        end

        # Default to sizes="auto" + loading="lazy" when no size hint was provided. sizes="auto" requires lazy loading and intrinsic width/height to work.
        if sizes_attr.nil? && source_format != "svg"
          sizes_attr = "auto"
          opts["loading"] ||= "lazy"
        end

        reserved_keys = %w[source widths formats alt sizes sizes_height oversample sources]
        extra_attrs = Utils.parse_html_attributes(opts, excluded_keys: reserved_keys)

        img_attrs = []
        img_attrs << %(alt="#{Utils.escape_html(alt)}") unless alt.empty?
        img_attrs << %(width="#{source_width}") << %(height="#{source_height}") if source_width
        img_attrs.concat(extra_attrs)

        if source_format == "svg"
          img_attrs.unshift(%(src="#{Utils.escape_html(OutputFilepath.new(source_path).public_url)}"))
          return %(<img #{img_attrs.join(' ')}/>)
        end

        widths = if opts.key?("widths")
                   Utils.parse_int_list(opts["widths"])
                 else
                   Utils.parse_int_list(config["default_widths"])
                 end

        formats = if opts.key?("formats")
                    Utils.parse_list(opts["formats"])
                  else
                    Utils.parse_list(config["default_formats"])
                  end.map { |f| Filepath.normalize_extension(f) }

        oversample = Float(opts["oversample"] || config["default_oversample"])

        extra_source_tags = ResponsiveImage.parse_extra_source_options(opts["sources"]).flat_map do |extra_opts|
          extra_source_path = Filepath.new(site, extra_opts.fetch("source"))
          extra_sources = ResponsiveImage.build_sources(extra_source_path, widths, formats)
          source_tags_for(extra_sources, oversample, sizes_attr, media: extra_opts["media"])
        end

        sources = ResponsiveImage.build_sources(source_path, widths, formats)
        source_tags = extra_source_tags + source_tags_for(sources, oversample, sizes_attr)

        # Use the largest webp variant as the img src, falling back to the source file when webp isn't generated.
        src_url = if sources["webp"] && !sources["webp"].empty?
                    sources["webp"].last[:path].public_url
                  else
                    OutputFilepath.new(source_path).public_url
                  end
        img_attrs.unshift(%(src="#{Utils.escape_html(src_url)}"))

        %(<picture>#{source_tags.join}<img #{img_attrs.join(' ')}/></picture>)
      end

      private

      def source_tags_for(variants, oversample, sizes_attr, media: nil)
        variants.map do |format, source|
          srcset = source.map { |c| "#{c[:path].public_url} #{(c[:width] / oversample).round}w" }.join(", ")
          source_parts = [%(type="#{Utils.escape_html(ResponsiveImage.mime_type(format))}"), %(srcset="#{Utils.escape_html(srcset)}")]
          source_parts << %(sizes="#{Utils.escape_html(sizes_attr)}") if sizes_attr
          source_parts << %(media="#{Utils.escape_html(media)}") if media && !media.empty?
          %(<source #{source_parts.join(' ')}/>)
        end
      end
    end
  end
end

Liquid::Template.register_tag("responsive_image", Jekyll::ResponsiveImage::ImageTag)
