# {% responsive_image "/assets/images/mountain.jpg" class="hero" %}
# {% responsive_image "/assets/images/mountain.jpg" widths="360,720,1080" formats="webp,jpg" class="hero" %}
# {% responsive_image "/assets/images/icon.png" widths="64,128" sizes="2em" %}

require_relative "../responsive_image"
require_relative "../utils"

module Jekyll
  module ResponsiveImage
    RESERVED_KEYS = %w[source widths formats alt sizes sizes_height oversample sources].freeze

    class ImageTag < Liquid::Tag
      def initialize(tag_name, text, tokens)
        super
        @tokens = Utils.parse_attributes(text, default_attributes: ["source"])
      end

      def render(context)
        site = context.registers[:site]
        opts = Utils.resolve_attributes(@tokens, context)

        source_path = Filepath.new(site, opts.fetch("source"))
        source_format = source_path.extension(normalize: true)

        # Get the alt text
        img_attrs = []
        alt = opts["alt"] || ResponsiveImage.get_alt_text(site, source_path)
        img_attrs << %(alt="#{Utils.escape_html(alt)}") unless alt.empty?

        # Early return for SVG images
        if source_format == "svg"
          img_attrs.concat(Utils.parse_html_attributes(opts, excluded_keys: RESERVED_KEYS))
          img_attrs.unshift(%(src="#{Utils.escape_html(OutputFilepath.new(source_path).public_url)}"))
          return %(<img #{img_attrs.join(' ')}/>)
        end

        # Build the sources
        widths = Utils.parse_int_list(opts.key?("widths") ? opts["widths"] : ResponsiveImage::CONFIG[:widths])
        formats = Utils.parse_list(opts.key?("formats") ? opts["formats"] : ResponsiveImage::CONFIG[:formats])
          .map { |f| Filepath.normalize_extension(f) }
        sources = ResponsiveImage.build_sources(source_path, widths, formats)

        # Determine the 'sizes' attribute
        sizes_attr = opts["sizes"]
        sizes_height = opts["sizes_height"]
        if !sizes_attr.nil?
          raise ArgumentError, "Use either sizes=... or sizes_height=..., not both, for #{source_path.relative_path}." if sizes_height
        elsif sizes_height
          # Determine the width from the height
          aspect_ratio = (sources[:width].to_f / sources[:height].to_f).round(4)
          sizes_attr = aspect_ratio == 1.0 ? sizes_height : "calc(#{sizes_height} * #{aspect_ratio})"
        else
          # Default to sizes="auto" + loading="lazy" when no size hint was provided. sizes="auto" requires lazy loading and intrinsic width/height to work.
          sizes_attr = "auto"
          opts["loading"] ||= "lazy"
        end
        oversample = Float(opts["oversample"] || ResponsiveImage::CONFIG[:oversample])

        # Build the <source> tags, including the extra sources with media attributes
        source_tags = ResponsiveImage.parse_extra_source_options(opts["sources"]).flat_map do |extra_opts|
          extra_source_path = Filepath.new(site, extra_opts.fetch("source"))
          extra_sources = ResponsiveImage.build_sources(extra_source_path, widths, formats)
          source_tags_for(extra_sources[:variants], oversample, sizes_attr, media: extra_opts["media"])
        end + source_tags_for(sources[:variants], oversample, sizes_attr)

        # Parse the attributes and assign the opaque class
        unless sources[:transparent]
          opts["class"] = [opts["class"], "opaque"].compact.reject(&:empty?).join(" ")
        end
        img_attrs.concat(Utils.parse_html_attributes(opts, excluded_keys: RESERVED_KEYS))
        img_attrs << %(width="#{sources[:width]}") << %(height="#{sources[:height]}")

        # Use the largest webp variant as the <img> src, falling back to the source file when webp isn't generated.
        src_url = if sources[:variants]["webp"] && !sources[:variants]["webp"].empty?
                    sources[:variants]["webp"].last[:path].public_url
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
