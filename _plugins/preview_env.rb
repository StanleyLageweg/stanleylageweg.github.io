module Jekyll
  module PreviewEnv
    IS_PREVIEW = ENV["JEKYLL_IS_PREVIEW"] == "true"
  end

  Hooks.register :site, :after_init do |site|
    site.config["is_preview"] = PreviewEnv::IS_PREVIEW
  end

  Hooks.register :site, :post_read do |site|
    next unless PreviewEnv::IS_PREVIEW
    site.pages.reject! { |page| page.name == "sitemap.xml" }
  end
end
