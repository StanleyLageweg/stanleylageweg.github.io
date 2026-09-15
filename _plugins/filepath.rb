require_relative "utils"

class Filepath
  attr_reader :site, :path, :relative_path
  protected :site

  def initialize(site, path)
    raise ArgumentError, "Site must be a Jekyll::Site instance." unless site.is_a?(Jekyll::Site)
    @site = site
    if (base = [site.dest, site.source].find { |b| path.start_with?(b) })
      @path = path
      @relative_path = path.sub("#{base}", "")
    else
      @path = File.join(site.source, path)
      @relative_path = path
    end
  end

  # /folder/subfolder/file.ext -> .ext
  def extension(normalize: false)
    ext = File.extname(@path)
    normalize ? Filepath.normalize_extension(ext) : ext
  end

  def self.normalize_extension(ext)
    # remove the leading dot
    ext = ext.to_s.downcase.sub(%r{\A\.}, "")
    ext = "jpg" if ext == "jpeg"
    ext
  end

  # /folder/subfolder/file.ext -> file.ext
  def basename(with_extension: true)
    with_extension ? File.basename(@path) : File.basename(@path, ".*")
  end

  # /folder/subfolder/file.ext -> /folder/subfolder
  def dirname(relative: false)
    relative ? File.dirname(@relative_path) : File.dirname(@path)
  end

  def exist?
    File.exist?(@path)
  end

  def mkdir_p
    FileUtils.mkdir_p(dirname)
  end

  def delete
    File.delete(@path) if exist?
  end

  def public_url
    File.join(@site.config["baseurl"].to_s, @relative_path)
  end

  def add_keep_file
    # Remove the leading slash
    keep_path = @relative_path.sub(%r{\A/}, "")
    @site.keep_files << keep_path unless @site.keep_files.include?(keep_path)
  end

  def mime_type
    stdout, stderr, status = Jekyll::Utils.fast_npx("ffmime", @path)
    raise Liquid::Error, "ffmime failed for '#{@path}': #{stderr.strip}" unless status.success?

    mime_type = stdout.strip
    raise Liquid::Error, "ffmime returned no MIME type for '#{@path}'." if mime_type.empty?

    mime_type
  end

  def ==(other)
    other.is_a?(Filepath) && @path == other.path
  end
  alias eql? ==

  def hash
    @path.hash
  end

  def to_s
    @path
  end
  alias to_str to_s
end
