# Similar to the 'default' filter, but only returns the default value if the input is nil, not if it's false.
# Example usage: {{ some_variable | nil_default: "Default value" }}
module Jekyll
  module NilDefaultFilter
    def nil_default(input, default_value)
      if input.nil?
        default_value
      else
        input
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::NilDefaultFilter)
