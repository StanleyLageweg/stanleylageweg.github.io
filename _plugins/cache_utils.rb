require 'yaml'
require 'fileutils'
require 'digest'

module CacheUtils
  IMAGE_CACHE = ".responsive-image-cache".freeze
  VIDEO_CACHE = ".responsive-video-cache".freeze

  def self.get_hash(filepath, site_source)
    # Check if the file is tracked and clean
    stdout, stderr, status = Open3.capture3('git', 'status', '--porcelain', filepath)
    if status.success? && stdout.empty?
      # Grab the precomputed hash from git
      stdout, stderr, status = Open3.capture3('git', 'ls-files', '-s', filepath)
      return stdout.split(/\s+/)[1] if status.success? && !stdout.empty?
    end

    # Compute the hash manually
    digest = Digest::SHA1.new
    digest << "blob #{File.stat(filepath).size}\0"
    digest.file(filepath)
    digest.hexdigest
  end

  def self.get_or_generate(site, source_path, cache_dir, configs, &generate)
    # Load the sidecar file
    sidecar_path = Filepath.new(site, File.join(cache_dir, ".#{source_path.relative_path}.yml"))
    begin
      cache_data = YAML.load_file(sidecar_path, aliases: true) || {}
    rescue Errno::ENOENT
      cache_data = {}
    end

    # Check if the source_hash is correct
    source_hash = get_hash(source_path, site.source)
    if cache_data[:source_hash] != source_hash
      cache_data = {}
      cache_data[:source_hash] = source_hash
    end
    cache_data[:outputs] ||= []

    # Clean up ghost entries immediately
    dest_dir = File.join(site.dest, source_path.dirname(relative: true))
    cache_data[:outputs].select! do |output|
      output.key?(:relative_path) && File.exist?(File.join(site.dest, output[:relative_path]))
    end

    # Create an iterator to find unused filename indexes
    base_path = File.join(source_path.dirname(relative: true), source_path.basename(with_extension: false))
    used_indices = cache_data[:outputs].filter_map do |output|
      output[:relative_path][/#{Regexp.escape(base_path)}-(\d+)\.[^.]+$/, 1]&.to_i
    end.to_set
    index_iterator = (1..).lazy.reject { |i| used_indices.include?(i) }

    # Find the existing output paths and pick new paths for files that we'll generate
    to_generate = []
    outputs = configs.map do |config|
      output = {config: config}
      output[:config][:extension] ||= source_path.extension(normalize: true)
      
      matched_output = cache_data[:outputs].find do |cached_output|
         cached_output[:config] == output[:config]
      end

      if matched_output
        output.store(:path, Filepath.new(site, File.join(site.dest, matched_output[:relative_path])))
      else
        output.store(:path, Filepath.new(site, File.join(site.dest, "#{base_path}-#{index_iterator.next}.#{output[:config][:extension]}")))
        to_generate << output
      end

      output
    end

    # Generate the outputs
    if to_generate.any?
      to_generate.each do |output|
        output[:path].delete
        output[:path].mkdir_p
      end

      generate.call(to_generate)

      # Check if all expected files were genereated
      to_generate.each do |output|
        raise "File (#{output[:path].relative_path}) was not generated" unless output[:path].exist?
        cache_data[:outputs] << output.except(:path).merge({relative_path: output[:path].relative_path})
      end

      sidecar_path.mkdir_p
      File.write(sidecar_path, YAML.dump(cache_data))
    end

    outputs.each { |outputs| outputs[:path].add_keep_file }

    outputs
  end

  def self.clean_sidecars(site)
    [IMAGE_CACHE, VIDEO_CACHE].each do |cache_dir|
      cache_dir = File.join(site.source, cache_dir)
      Dir.glob(File.join(cache_dir, "**/*.yml"), File::FNM_DOTMATCH).each do |sidecar_path|
        next if File.directory?(sidecar_path)
        
        begin
          cache_data = YAML.load_file(sidecar_path, aliases: true) || {}
        rescue Errno::ENOENT
          cache_data = {}
        end
        cache_data[:outputs] ||= []

        cache_data[:outputs].select! do |output|
          File.exist?(File.join(site.dest, output[:relative_path]))
        end

        cache_data[:outputs].empty? ? File.delete(sidecar_path) : File.write(sidecar_path, YAML.dump(cache_data))
      end
    end
  end
end
