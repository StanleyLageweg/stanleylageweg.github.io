require 'open3'

def minify_html(file)
  return unless file.output && file.output_ext == '.html'

  started_at = Time.now
  Jekyll.logger.info("HTML Minify:", "minifying #{file.relative_path}")
  
  stdout, stderr, status = Open3.capture3('npx', 'html-minifier-terser',
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

  if status.success?
    Jekyll.logger.info("HTML Minify:", "done in #{(Time.now - started_at).round(2)} seconds.")
    file.output = stdout
  else
    Jekyll.logger.warn("HTML Minify:", "failed to minify '#{file.relative_path}': #{stderr.strip}")
  end
end

# Minify pages
Jekyll::Hooks.register :pages, :post_render do |page|
  minify_html(page)
end

# Minify posts and collections
Jekyll::Hooks.register :documents, :post_render do |document|
  minify_html(document)
end

