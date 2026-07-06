# {{ page.header.image | responsive_image }}
# {{ page.header.image | responsive_image_alt }}

require_relative "../responsive_image"

module Jekyll
  module ResponsiveImageFilter
    OUTPUT_WIDTH = 1920.freeze
    OUTPUT_FORMAT = "webp".freeze

    def responsive_image(input)
      return input if input.nil? || input.to_s.empty?

      source_rel = input.to_s
      source_format = Jekyll::ResponsiveImage.normalize_format(File.extname(source_rel))
      return source_rel if source_format == "svg"

      site = @context.registers[:site]
      source_path = Jekyll::ResponsiveImage.get_source_path(site, source_rel)
      sources = Jekyll::ResponsiveImage.build_sources(site, source_path, source_rel, [OUTPUT_WIDTH], [OUTPUT_FORMAT])
      sources[OUTPUT_FORMAT].last[:url] || source_rel
    end

    def responsive_image_alt(input)
      return input if input.nil? || input.to_s.empty?

      site = @context.registers[:site]
      Jekyll::ResponsiveImage.get_alt_text(site, input.to_s, Jekyll::ResponsiveImage.config_for(site))
    end
  end
end

Liquid::Template.register_filter(Jekyll::ResponsiveImageFilter)
