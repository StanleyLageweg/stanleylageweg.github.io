# Validates that the specified variable is present and not empty.
# Usage: {% required variable_name %}
module Jekyll
  class RequiredTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup.strip
    end

    def render(context)
      value = context[@markup]
      if value.nil? || (value.respond_to?(:empty?) && value.empty?)
        raise Liquid::Error, "Missing parameter '#{@markup}'."
      end
    end
  end
end

Liquid::Template.register_tag('required', Jekyll::RequiredTag)
