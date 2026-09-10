require_relative "utils"

class Filepath
  attr_reader :site, :path, :relative_path
  protected :site

  def initialize(site, path)
    raise ArgumentError, "Site must be a Jekyll::Site instance." unless site.is_a?(Jekyll::Site)
    @site = site
    if [site.dest, site.source].any? { |base| path.start_with?(base) }
      @path = path
      @relative_path = path.sub("#{base}/", "")
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

  # /folder/subfolder/file.ext -> file
  def basename
    File.basename(@path, extension)
  end

  # /folder/subfolder/file.ext -> /folder/subfolder
  def dirname
    File.dirname(@path)
  end

  def exist?
    File.exist?(@path)
  end

  def make_directory
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

class OutputFilepath < Filepath
  attr_reader :source_path

  def initialize(source_path, suffix: "", extension: nil)
    raise ArgumentError, "Source path must be a Filepath instance." unless source_path.is_a?(Filepath)
    @site = source_path.site
    @source_path = source_path.path
    ext = extension || source_path.extension(normalize: true)
    @relative_path = File.join(File.dirname(source_path.relative_path), "#{source_path.basename}#{suffix}.#{ext}")
    @path = File.join(@site.dest, @relative_path)
  end

  def up_to_date?
    raise ArgumentError, "Source file not found: #{@source_path}" unless File.exist?(@source_path)
    exist? && File.mtime(@path) >= File.mtime(@source_path)
  end
end