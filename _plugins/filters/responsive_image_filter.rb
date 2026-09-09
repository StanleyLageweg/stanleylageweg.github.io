# {{ page.header.image | responsive_image }}
# {{ page.header.image | responsive_image_alt }}

require_relative "../responsive_image"

module Jekyll
  module ResponsiveImageFilter
    OUTPUT_WIDTH = 1920.freeze
    OUTPUT_FORMAT = "webp".freeze

    def responsive_image(input)
      return input if input.nil? || input.to_s.empty?

      source_path = Filepath.new(@context.registers[:site], input.to_s)
      source_format = source_path.extension(normalize: true)
      return Utils.escape_html(source_path.public_url) if source_format == "svg"

      
      sources = Jekyll::ResponsiveImage.build_sources(source_path, [OUTPUT_WIDTH], [OUTPUT_FORMAT])
      Utils.escape_html(sources[OUTPUT_FORMAT].last[:path].public_url || source_path.public_url)
    end

    def responsive_image_alt(input)
      return input if input.nil? || input.to_s.empty?

      site = @context.registers[:site]
      source_path = Filepath.new(@context.registers[:site], input.to_s)
      Jekyll::ResponsiveImage.get_alt_text(site, source_path, Jekyll::ResponsiveImage.config_for(site))
    end
  end
end

Liquid::Template.register_filter(Jekyll::ResponsiveImageFilter)
