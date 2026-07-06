# https://jekyllrb.com/docs/plugins/hooks/ 
#
# :site - Encompasses the entire site
# :pages - Allows fine-grained control over all pages in the site
# :documents - Allows fine-grained control over all documents in the site including posts and documents in user-defined collections
# :posts - Allows fine-grained control over all posts in the site without affecting documents in user-defined collections
# :clean - Fine-grained control on the list of obsolete files determined to be deleted during the site's cleanup phase.

# Just after the site initializes. Good for modifying the configuration of the site. Triggered once per build / serve session
Jekyll::Hooks.register :site, :after_init do |site|
  Jekyll::ResponsiveImage.reset_after_build(site)
end

# After all source files have been read and loaded from disk
Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::BuildJs.exclude_source_files(site)
end

# Just before rendering the whole site
Jekyll::Hooks.register :site, :pre_render do |site|
  Jekyll::BuildJs.build(site)
end

# Just before rendering a document
Jekyll::Hooks.register :documents, :pre_render do |document|
  Jekyll::CollectionsOutput.run(document)
end

# After rendering a page, but before writing it to disk
Jekyll::Hooks.register :pages, :post_render do |page|
  Jekyll::BuildHtml.minify(page)
end

# After rendering a document, but before writing it to disk
Jekyll::Hooks.register :documents, :post_render do |document|
  Jekyll::BuildHtml.minify(document)
end

# After rendering the whole site, but before writing any files
Jekyll::Hooks.register :site, :post_render do |site|
  Jekyll::ExcludeUnusedAssets.run(site)
end

# After writing all of the rendered files to disk
Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::LogOutputSize.run(site)
end
