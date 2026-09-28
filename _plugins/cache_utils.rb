require 'digest'
require 'open3'
require 'set'

require_relative 'yaml_cache'

module CacheUtils
  IMAGE_CACHE = ".jekyll-cache/responsive-image-cache.yml".freeze
  VIDEO_CACHE = ".jekyll-cache/responsive-video-cache.yml".freeze

  def self.get_hash(filepath)
    # Check if the file is tracked and clean
    stdout, status = Open3.capture2('git', 'status', '--porcelain', filepath)
    if status.success? && stdout.empty?
      # Grab the precomputed hash from git
      stdout, status = Open3.capture2('git', 'ls-files', '-s', filepath)
      return stdout.split(/\s+/)[1] if status.success? && !stdout.empty?
    end

    # Compute the hash manually
    digest = Digest::SHA1.new
    digest << "blob #{File.stat(filepath).size}\0"
    digest.file(filepath)
    digest.hexdigest
  end

  def self.get_or_generate(site, source_path, cache_name, configs, &generate)
    cache = YamlCache.instance(File.join(site.source, "#{cache_name}"))
    source_hash = get_hash(source_path)

    # Create an iterator to find unused filename indexes
    base_path = File.join(source_path.dirname(relative: true), source_path.basename(with_extension: false))
    used_indices = Dir.glob(File.join(site.dest, "#{base_path}-*")).filter_map do |path|
      path[/#{Regexp.escape(base_path)}-(\d+)\.[^.]+$/, 1]&.to_i
    end.to_set
    index_iterator = (1..).lazy.reject { |i| used_indices.include?(i) }

    # Find the existing output paths and pick new paths for files that we'll generate
    to_generate = []
    outputs = configs.map do |config|
      config[:extension] ||= source_path.extension(normalize: true)

      cache_key = "#{source_path.relative_path}:#{config}:#{source_hash}"
      output = cache.key?(cache_key) && { relative_path: cache[cache_key] }

      unless output && File.exist?(File.join(site.dest, output[:relative_path]))
        output = {
          relative_path: "#{base_path}-#{index_iterator.next}.#{config[:extension]}"
        }
        to_generate << output
      end

      output[:config] = config
      output[:path] = Filepath.new(site, File.join(site.dest, output[:relative_path]))
      output[:cache_key] = cache_key
      output
    end

    # Generate the outputs
    if to_generate.any?
      to_generate.each do |output|
        output[:path].delete
        output[:path].mkdir_p
      end

      generate.call(to_generate)

      missing_outputs = []
      to_generate.each do |output|
        if output[:path].exist?
          cache[output[:cache_key]] = output[:relative_path]
        else
          missing_outputs << output
          cache.delete(output[:cache_key])
        end
      end

      if missing_outputs.any?
        missing_paths = missing_outputs.map { |output| output[:relative_path] }
        raise "File(s) (#{missing_paths.join(', ')}) was/were not generated"
      end
    end

    outputs.each { |output| output[:path].add_keep_file }

    outputs
  end
end
