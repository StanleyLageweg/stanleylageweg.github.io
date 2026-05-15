# Raises an error: {% raise_error "This is an error message." %}
module Jekyll
  class RaiseError < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup.strip
    end
    
    def render(context)
      parsed_message = Liquid::Template.parse(@markup).render(context)
      raise Liquid::Error, parsed_message
    end
  end
end

Liquid::Template.register_tag('raise_error', Jekyll::RaiseError)
