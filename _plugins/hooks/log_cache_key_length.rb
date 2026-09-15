module Jekyll
  module LogCacheKeyLength
    MAX_KEY_LENGTH = 512

    module_function

    def run
      image_cache_key = "responsive-images-#{Jekyll::ResponsiveImage.get_cache_key}-#{Jekyll::ResponsiveImage.get_optional_cache_key}-#{"__hash__" * 8}-#{"__hash__" * 5}"
      if image_cache_key.length <= MAX_KEY_LENGTH
          Jekyll.logger.info("Cache key length:", "responsive-images (#{image_cache_key.length}/#{MAX_KEY_LENGTH})")
      else
          raise "Image cache key too long (#{image_cache_key.length}/#{MAX_KEY_LENGTH}): '#{image_cache_key}'"
      end

      video_cache_key = "responsive-videos-#{Jekyll::ResponsiveVideo.get_cache_key}-#{Jekyll::ResponsiveVideo.get_optional_cache_key}-#{"__hash__" * 8}-#{"__hash__" * 5}"
      if video_cache_key.length <= MAX_KEY_LENGTH
          Jekyll.logger.info("Cache key length:", "responsive-videos (#{video_cache_key.length}/#{MAX_KEY_LENGTH})")
      else
          raise "Video cache key too long (#{video_cache_key.length}/#{MAX_KEY_LENGTH}): '#{video_cache_key}'" 
      end
    end
  end
end
