# {{ page.header.image | responsive_image }}
# {{ page.header.image | responsive_image_alt }}

require_relative "../responsive_image"

module Jekyll
  module ResponsiveImageFilter
    def responsive_image(input, output_width = 1920, output_format = "webp", convert_svg = false)
      return input if input.nil? || input.to_s.empty?

      site = @context.registers[:site]
      source_path = Filepath.new(site, input.to_s)
      source_format = source_path.extension(normalize: true)

      if source_format == "svg" && !convert_svg
        source = ResponsiveImage.build_svg(site, source_path)
        return Utils.escape_html(source[:path].public_url)
      end
      
      sources = Jekyll::ResponsiveImage.build_sources(site, source_path, [output_width], [output_format])
      Utils.escape_html(sources[:variants][output_format].last[:path].public_url || source_path.public_url)
    end

    def responsive_image_alt(input)
      return input if input.nil? || input.to_s.empty?

      site = @context.registers[:site]
      source_path = Filepath.new(site, input.to_s)
      Jekyll::ResponsiveImage.get_alt_text(site, source_path)
    end
  end
end

Liquid::Template.register_filter(Jekyll::ResponsiveImageFilter)
