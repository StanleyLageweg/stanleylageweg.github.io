# {% responsive_image "/assets/images/mountain.jpg" class="hero" %}
# {% responsive_image "/assets/images/mountain.jpg" widths="360,720,1080" formats="webp,jpg" class="hero" %}
# {% responsive_image "/assets/images/icon.png" widths="64,128" sizes="2em" %}

require_relative "../responsive_image"

module Jekyll
  module ResponsiveImage
    class ImageTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @tokens = ResponsiveImage.parse_tag_text(text)
      end

      def render(context)
        site = context.registers[:site]
        config = ResponsiveImage.config_for(site)
        opts = ResponsiveImage.resolve_tokens(@tokens, context)

        source_rel = opts.fetch("source")
        source_path = ResponsiveImage.get_source_path(site, source_rel)
        source_format = ResponsiveImage.normalize_format(File.extname(source_path))

        alt = opts["alt"] || ResponsiveImage.get_alt_text(site, source_rel, config)
        sizes_attr = opts["sizes"]
        sizes_height = opts["sizes_height"]
        raise ArgumentError, "Use either sizes=... or sizes_height=..., not both, for #{source_rel}." if sizes_attr && sizes_height

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

        reserved_keys = %w[source widths formats alt sizes sizes_height oversample]
        extra_attrs = opts.reject { |k, _| reserved_keys.include?(k) }.map do |k, v|
          %(#{k}="#{escape_html(v)}")
        end

        img_attrs = []
        img_attrs << %(alt="#{escape_html(alt)}") unless alt.empty?
        img_attrs << %(width="#{source_width}") << %(height="#{source_height}") if source_width
        img_attrs.concat(extra_attrs)

        if source_format == "svg"
          src_url = ResponsiveImage.public_url(site, File.join(site.dest, source_rel))
          img_attrs.unshift(%(src="#{escape_html(src_url)}"))
          return %(<img #{img_attrs.join(' ')}/>)
        end

        widths = if opts.key?("widths")
                   ResponsiveImage.parse_int_list(opts["widths"])
                 else
                   ResponsiveImage.parse_int_list(config["default_widths"])
                 end

        formats = if opts.key?("formats")
                    ResponsiveImage.parse_list(opts["formats"])
                  else
                    ResponsiveImage.parse_list(config["default_formats"])
                  end.map { |f| ResponsiveImage.normalize_format(f) }

        oversample = Float(opts["oversample"] || config["default_oversample"])

        sources = ResponsiveImage.build_sources(site, source_path, source_rel, widths, formats)

        # Use the largest webp variant as the img src, falling back to the source file when webp isn't generated.
        src_url = if sources["webp"] && !sources["webp"].empty?
                    sources["webp"].last[:url]
                  else
                    ResponsiveImage.public_url(site, File.join(site.dest, source_rel))
                  end
        img_attrs.unshift(%(src="#{escape_html(src_url)}"))

        source_tags = sources.map do |format, source|
          srcset = source.map { |c| "#{c[:url]} #{(c[:width] / oversample).round}w" }.join(", ")
          source_parts = [%(type="#{escape_html(ResponsiveImage.mime_type(format))}"), %(srcset="#{escape_html(srcset)}")]
          source_parts << %(sizes="#{escape_html(sizes_attr)}") if sizes_attr
          %(<source #{source_parts.join(' ')}/>)
        end

        %(<picture>#{source_tags.join}<img #{img_attrs.join(' ')}/></picture>)
      end

      private

      def escape_html(value)
        CGI.escapeHTML(value.to_s)
      end
    end
  end
end

Liquid::Template.register_tag("responsive_image", Jekyll::ResponsiveImage::ImageTag)
