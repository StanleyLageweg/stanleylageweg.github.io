module Jekyll
  # Captures a block of Markdown, renders it through Jekyll's Markdown converter,
  # and stores the resulting HTML in the provided variable name.
  #
  # Usage:
  # {% capture_markdown variable_name %}
  # Markdown content here
  # {% endcapture_markdown %}
  class CaptureMarkdownTag < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super

      @variable_name = markup.to_s.strip
      if @variable_name.empty? || @variable_name.include?(" ")
        raise Liquid::SyntaxError, "Usage: capture_markdown variable_name"
      end
    end

    def render(context)
      rendered_markdown = super.to_s.strip
      site = context.registers[:site]
      converter = site.find_converter_instance(Jekyll::Converters::Markdown)
      context.scopes.last[@variable_name] = converter.convert(rendered_markdown)
      ""
    end
  end
end

Liquid::Template.register_tag("capture_markdown", Jekyll::CaptureMarkdownTag)