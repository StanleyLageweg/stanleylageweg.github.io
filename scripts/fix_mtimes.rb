#!/usr/bin/env ruby

require "net/http"
require "json"
require "time"
require "uri"

# Sets git-tracked repository files to their latest git commit date
def restore_git_mtimes
  seen = {}
  current_time = nil

  `git log --name-only --format="TIME:%ct"`.each_line do |line|
      line = line.strip
      next if line.empty?

      if line.start_with?("TIME:")
      current_time = Time.at(line.split(":")[1].to_i)
      elsif current_time && File.file?(line) && !seen[line]
      File.utime(current_time, current_time, line) rescue nil
      seen[line] = true
      end
  end
  puts "Restore git mtimes: updated mtime for #{seen.size} file(s)"
end

# Fetches creation timestamp for a matched cache key via GitHub REST API
def fetch_cache_created_at(key)
  return nil if key.nil? || key.strip.empty?

  repo = ENV["GITHUB_REPOSITORY"]
  token = ENV["GITHUB_TOKEN"]

  if repo.nil? || repo.empty? || token.nil? || token.empty?
    raise "Error: GITHUB_REPOSITORY and GITHUB_TOKEN environment variables must be set."
  end

  uri = URI("https://api.github.com/repos/#{repo}/actions/caches?key=#{URI.encode_www_form_component(key)}")
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{token}"
  req["Accept"] = "application/vnd.github+json"
  req["User-Agent"] = "Ruby-Mtime-Restorer"

  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(req)
  end

  raise "GitHub API error (#{res.code}): #{res.body}" unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)
  caches = data["actions_caches"] || []
  raise "No cache metadata found on GitHub matching key '#{key}'" if caches.empty?

  matched_cache = caches.find { |c| c["key"] == key } || caches.first
  created_at = Time.parse(matched_cache["created_at"])

  puts "Found cache '#{matched_cache["key"]}' created at #{created_at}"
  created_at
end

# Filters files in `dir` by allowed extensions and updates their mtimes
def restore_cache_mtimes(key, dir, extensions_str)
  if key.nil? || key.strip.empty?
    puts "Cache key empty (cache miss). Skipping mtime update."
    return
  end

  return unless Dir.exist?(dir)

  created_at = fetch_cache_created_at(key)
  return unless created_at

  extensions = extensions_str.split(',').map { |e| e.strip.downcase.sub(/^\./, '') }
  file_count = 0

  Dir.glob("#{dir}/**/*", File::FNM_DOTMATCH).each do |file|
    next if File.directory?(file)

    ext = File.extname(file).downcase.sub(/^\./, '')
    if extensions.include?(ext)
      File.utime(created_at, created_at, file) rescue nil
      file_count += 1
    end
  end

  puts "Restore cache mtimes: updated mtime for #{file_count} file(s)"
end

case ARGV[0]
when "git"
  restore_git_mtimes
when "cache"
  key = ARGV[1]
  dir = ARGV[2]
  exts = ARGV[3]
  if key.nil? || dir.nil? || exts.nil?
    raise ArgumentError, "Usage: ruby scripts/fix_mtimes.rb cache <matched_key> <directory> <extensions>"
  end
  restore_cache_mtimes(key, dir, exts)
else
  raise ArgumentError, 'Usage: "ruby scripts/fix_mtimes.rb git" or "ruby scripts/fix_mtimes.rb cache <matched_key> <directory> <extensions>"'
end
