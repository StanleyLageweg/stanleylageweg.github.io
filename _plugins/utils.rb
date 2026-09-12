require "liquid"

module Jekyll
  module Utils
    TAG_ATTRIBUTES = /(?:\A|\s)(\w+)\s*=\s*(#{Liquid::QuotedFragment})/o

    module_function

    def log_duration(topic, &func)
      started_at = Time.now
      message = func.call
      elapsed = (Time.now - started_at).round(2)
      Jekyll.logger.info(topic, "#{message} (#{elapsed} seconds)") if message
    end

    def silence_output
      orig_stdout = $stdout.clone
      $stdout.reopen File::NULL, 'w'
      yield
    ensure
      $stdout.reopen orig_stdout
    end

    def fast_npx(package, *args)
      # Open3.capture3("npx", "--no-install", package, *args)
      Open3.capture3(File.join("./node_modules/.bin", package), *args)
    end

    def escape_html(value)
      CGI.escapeHTML(value.to_s)
    end

    def cache_key(value)
      case value
      when Hash
        "{" + value.sort_by { |key, _| key.to_s }.map { |key, item| "#{cache_key(key)}:#{cache_key(item)}" }.join(";") + "}"
      when Array
        "[" + value.map { |item| cache_key(item) }.join(";") + "]"
      else
        value.to_s
      end
    end

    def parse_html_attributes(attributes, excluded_keys: [])
      attributes
        .reject { |key, _| excluded_keys.include?(key) }
        .map { |key, value| %(#{key}="#{escape_html(value)}") }
    end

    def parse_list(value)
      case value
      when nil
        []
      when Array
        value.flatten.map(&:to_s).map(&:strip).reject(&:empty?)
      else
        value.to_s.split(",").map(&:strip).reject(&:empty?)
      end
    end

    def parse_int_list(value)
      Utils.parse_list(value).map do |item|
        Integer(item)
      rescue ArgumentError
        raise ArgumentError, "Invalid size '#{item}'. Sizes must be integers."
      end
    end

    # Parses ordered default attributes followed by named attributes (name="value").
    # Needs to be resolved using resolve_attributes.
    def parse_attributes(text, default_attributes: [])
      remaining_text = text.to_s.strip
      tokens = []

      default_attributes.each do |attribute|
        value_match = remaining_text.match(/\A(\S+)\s*(.*)/m)
        raise ArgumentError, "Tag requires a #{attribute} attribute" if value_match.nil?

        tokens << build_token(attribute, value_match[1])
        remaining_text = value_match[2]
      end

      remaining_text.scan(TAG_ATTRIBUTES) do |key, value|
        tokens << build_token(key, value)
      end
      tokens
    end

    # Resolves all parsed tokens into an attribute hash.
    def resolve_attributes(tokens, context)
      tokens.each_with_object({}) do |token, options|
        options[token[:key]] = token[:resolve].call(context)
      end
    end

    def self.build_token(key, value)
      resolver = if value.start_with?('"', "'") && value.include?("{{")
          template = Liquid::Template.parse(value[1..-2])
          ->(context) { template.render(context) }
        else
          expr = Liquid::Expression.parse(value)
          ->(context) { context.evaluate(expr) }
        end
      { key: key, resolve: resolver }
    end
    private_class_method :build_token

  end
end
