require "set"

module Jekyll

  # Validates that only the specified fields are present.
  # Usage: {% validate_fields <object> required="a, b" optional="c, d" %}
  class ValidateFieldsTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @object_expr, options = parse_markup(markup)

      if @object_expr.nil? || @object_expr.empty?
        raise Liquid::SyntaxError, 'Usage: validate_fields <object> required="a, b" optional="c, d".'
      end

      # Get and check the options
      @required = split_list(options["required"])
      @optional = split_list(options["optional"])
      if @required.empty? && @optional.empty?
        raise Liquid::SyntaxError, "validate_fields: requires at least one of required= or optional=."
      end

      # Check for unknown options
      allowed_options = %w[required optional]
      unknown_options = options.keys - allowed_options
      if unknown_options.any?
        raise Liquid::SyntaxError,
          "validate_fields: unknown option(s): '#{unknown_options.join(', ')}'. " \
          "Allowed options are: '#{allowed_options.join(', ')}'."
      end
    end

    def render(context)
      keys = normalize_to_hash(context, @object_expr).keys.map(&:to_s)
      allowed  = (@required + @optional).uniq
      missing = @required - keys
      if missing.any?
        raise Liquid::Error, "validate_fields: '#{@object_expr}' is missing required field(s): '#{missing.join(', ')}'."
      end

      unexpected = keys - allowed
      if unexpected.any?
        Jekyll.logger.warn "validate_fields:",
          "'#{@object_expr}' has unexpected field(s): '#{unexpected.join(', ')}'. " \
          "Did you mean: '#{(allowed - keys).join(', ')}'?"
      end

      ""
    end

    private

    def parse_markup(markup)
      markup = markup.to_s.strip
      return ["", {}] if markup.empty?

      parts = markup.split(/\s+/, 2)
      object_expr = parts[0]
      options = {}

      if parts[1]
        parts[1].scan(/(\w+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s]+))/) do |key, dq, sq, bare|
          options[key] = dq || sq || bare
        end
      end

      [object_expr, options]
    end

    def normalize_to_hash(context, expr)
      object = Liquid::VariableLookup.parse(expr).evaluate(context)
      if object.nil?
        raise Liquid::Error, "validate_fields: '#{expr}' is undefined."
      end

      return {} if object.nil?
      return object if object.is_a?(Hash)
      return object.to_h if object.respond_to?(:to_h)

      if object.respond_to?(:keys) && object.respond_to?(:[])
        object.keys.each_with_object({}) { |k, h| h[k.to_s] = object[k] }
      elsif object.respond_to?(:each)
        object.each_with_object({}) do |item, h|
          k, v = item
          h[k.to_s] = v
        end
      else
        raise Liquid::Error, "validate_fields: object must be hash-like, got #{object.class}."
      end
    end

    def split_list(value)
      value.to_s.split(",").map(&:strip).reject(&:empty?)
    end
  end
end

Liquid::Template.register_tag("validate_fields", Jekyll::ValidateFieldsTag)