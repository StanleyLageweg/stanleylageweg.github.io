require 'fileutils'
require 'set'
require 'yaml'
require "active_support/core_ext/object/deep_dup"

# A key-value cache which lazy-loads from a yaml file and writes any changes on exit.
class YamlCache
  @instances = {}

  class << self
    def instance(file_path)
      @instances[file_path] ||= new(file_path)
    end

    def flush_all(prune_stale: false)
      @instances.each_value { |instance| instance.flush(prune_stale: prune_stale) }
    end
  end

  attr_reader :file_path
  private_class_method :new

  def initialize(file_path)
    @file_path = file_path
    @data = nil
    @dirty = false
    @accessed_keys = Set.new
  end

  # Returns a deep copy of the cached data for the key, or nil if there's no cached data
  def [](key)
    if key?(key)
      @accessed_keys.add(key)
      load_data[key].deep_dup
    end
  end

  def []=(key, value)
    load_data[key] = value.deep_dup
    @accessed_keys.add(key)
    mark_dirty
  end

  def delete(key)
    if load_data.key?(key)
      load_data.delete(key)
      @accessed_keys.delete(key)
      mark_dirty
    end
  end

  def key?(key)
    has_key = load_data.key?(key)
    @accessed_keys.add(key) if has_key
    has_key
  end

  def size
    load_data.size
  end

  def mark_dirty
    @dirty = true
  end

  def flush(prune_stale: false)
    return unless @data

    prune_unused_keys! if prune_stale
    return unless @dirty

    FileUtils.mkdir_p(File.dirname(@file_path))
    File.write(@file_path, YAML.dump(@data))
    @dirty = false
  end

  private

  def prune_unused_keys!
    unused_keys = @data.keys - @accessed_keys.to_a
    return if unused_keys.empty?

    unused_keys.each { |key| @data.delete(key) }
    mark_dirty
  end

  def load_data
    return @data if @data
    @data = (File.exist?(@file_path) && YAML.load_file(@file_path, aliases: true)) || {}
  end
end

at_exit do
  successful_exit = $!.nil? || ($!.is_a?(SystemExit) && $!.success?)
  YamlCache.flush_all(prune_stale: successful_exit)
end
