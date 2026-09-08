require "liquid"

module Jekyll
  module Utils
    TAG_ATTRIBUTES = /(?:\A|\s)(\w+)\s*=\s*(#{Liquid::QuotedFragment})/o

    module_function
    
    def get_source_path(site, source_rel)
      source_path = File.join(site.source, source_rel)
      raise Liquid::Error, "Source not found: #{source_rel}" unless File.exist?(source_path)
      source_path
    end

    def to_relative_path(site, path)
      [site.dest, site.source].each do |base|
        if path.start_with?(base)
          return path.sub("#{base}/", "")
        end
      end
      path
    end

    def public_url(site, path)
      rel = to_relative_path(site, path)
      baseurl = site.config["baseurl"].to_s
      baseurl = "" if baseurl == "/"
      baseurl = "/#{baseurl}" unless baseurl.empty? || baseurl.start_with?("/")
      baseurl = baseurl.chomp("/")
      url = "#{baseurl}/#{rel}".gsub(%r{/+}, "/")
      url.empty? ? "/#{rel}" : url
    end

    def add_keep_file(site, path)
      relative_path = to_relative_path(site, path)
      site.keep_files << relative_path unless site.keep_files.include?(relative_path)
    end

    def get_mime_type(path)
      stdout, stderr, status = Open3.capture3("npx", "--no-install", "ffmime", path)
      raise Liquid::Error, "ffmime failed for '#{path}': #{stderr.strip}" unless status.success?

      mime_type = stdout.strip
      raise Liquid::Error, "ffmime returned no MIME type for '#{path}'." if mime_type.empty?

      mime_type
    rescue Errno::ENOENT
      raise Liquid::Error, "Unable to run ffmime. Install Node packages with npm install."
    end

    def is_output_up_to_date?(source_path, output_path)
      throw Liquid::Error, "Source file not found: #{source_path}" unless File.exist?(source_path)
      return false unless File.exist?(output_path)

      source_mtime = File.mtime(source_path)
      output_mtime = File.mtime(output_path)
      output_mtime >= source_mtime
    end

    def escape_html(value)
      CGI.escapeHTML(value.to_s)
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
