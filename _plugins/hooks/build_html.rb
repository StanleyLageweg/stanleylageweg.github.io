module Jekyll
  module BuildHtml
    module_function

    def minify(file)
      return unless file.output && file.output_ext == '.html'

      Utils.log_duration("HTML Minify:") do
        stdout, stderr, status = Utils.fast_npx(
          'html-minifier-terser',
          '--collapse-boolean-attributes',
          '--collapse-whitespace',
          '--conservative-collapse',
          '--minify-css',
          '--minify-js',
          '--minify-urls',
          '--remove-comments',
          '--remove-empty-attributes',
          '--remove-redundant-attributes',
          '--remove-script-type-attributes',
          '--remove-style-link-type-attributes',
          '--sort-attributes',
          '--sort-class-name',
          stdin_data: file.output)

        raise "HTML Minify failed: #{stderr.strip}" unless status.success?

        file.output = stdout
        "minified #{file.relative_path}"
      end
    end
  end
end

