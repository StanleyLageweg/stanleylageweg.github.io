module Jekyll
  module BuildHtml
    module_function

    def minify(file)
      return unless file.output && file.output_ext == '.html'

      Utils.log_duration("HTML Minify:") do
        file.output = Utils.npx_command(
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

        "minified #{file.relative_path}"
      end
    end
  end
end

