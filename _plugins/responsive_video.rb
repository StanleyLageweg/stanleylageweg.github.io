require "fileutils"
require "json"
require "open3"
require "pathname"

require "jekyll"

module Jekyll
  module ResponsiveVideo
    DEFAULT_CONFIG = {
      "default_formats" => ["av1", "vp9", "h264"]
    }.freeze

    # crf = Constant Rate Factor, tradeff between quality and file size. Lower values increase both quality and file size.
    # preset = tradeoff between encoding speed and file size. Lower values decrease file size but increase encoding time.
    PROFILES = {
      "h264" => {
        extension: "mp4",
        video_codec: "libx264",
        crf: 27, # 0 to 51, 0 = lossless, 20 to 23 = balanced, 28 to 30 = small file.
        preset: "slow", # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo.
        audio_codec: "aac",
        audio_bitrate: "128k", # 128k to 192k = recommended for web
      },
      "vp9" => {
        extension: "webm",
        video_codec: "libvpx-vp9",
        crf: 35, # 0 to 63, 25 to 31 = balanced, 35 to 40 = small file.
        preset: 3, # -8 to 8, 2 to 4 = recommended
        audio_codec: "libopus",
        audio_bitrate: "96k", # 64k to 128k = recommended for web
      },
      "av1" => {
        extension: "webm",
        video_codec: "libsvtav1",
        crf: 40, # 0 to 63, 28 to 32 = balanced, 38 to 45 = small file.
        preset: 6, # -2 to 13, 2 to 6 = recommended
        audio_codec: "libopus",
        audio_bitrate: "96k", # 64k to 128k = recommended for web
      }
    }.freeze

    module_function

    def config_for(site)
      DEFAULT_CONFIG.merge(site.config.fetch("responsive_video", {}))
    end

    def parse_formats(value)
      formats = Utils.parse_list(value).map(&:downcase).uniq
      invalid = formats - PROFILES.keys
      raise ArgumentError, "Unsupported video format(s): #{invalid.join(', ')}." unless invalid.empty?
      raise ArgumentError, "At least one video format is required." if formats.empty?
      formats
    end

    def get_dimensions(source_path)
      stdout, stderr, status = Open3.capture3(
        "ffprobe",
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height",
        "-of", "json",
        source_path
      )
      raise Liquid::Error, "ffprobe failed for '#{source_path}': #{stderr.strip}" unless status.success?

      stream = JSON.parse(stdout).fetch("streams").first
      { width: Integer(stream.fetch("width")), height: Integer(stream.fetch("height")) }
    rescue Errno::ENOENT
      raise Liquid::Error, "Unable to run ffprobe. Install FFmpeg and make sure ffprobe is available on PATH."
    rescue JSON::ParserError, KeyError, TypeError, ArgumentError => error
      raise Liquid::Error, "Unable to read video metadata for '#{source_path}': #{error.message}"
    end

    def build_sources(site, source_path, source_rel, formats, config, muted: false)
      dimensions = get_dimensions(source_path)
      scale = dimensions[:width] > 1920 ? 1920.0 / dimensions[:width] : 1.0

      # Determine which variants we need
      variants = formats.map do |format|
        {
          format: format,
          extension: PROFILES.fetch(format)[:extension],
          path: get_output_path(site, source_rel, format, muted: muted)
        }
      end

      # Determine which variants need to be generated
      variants_to_generate = variants.reject { |variant| Utils.is_output_up_to_date?(source_path, variant[:path]) }
      variants_to_generate.each { |variant| FileUtils.mkdir_p(File.dirname(variant[:path])) }

      # Generate the variants using ffmpeg
      unless variants_to_generate.empty?
        started_at = Time.now
        command = build_ffmpeg_command(source_path, variants_to_generate, config, muted: muted, scale: scale)
        _stdout, stderr, status = Open3.capture3(*command)
        unless status.success?
          variants_to_generate.each { |variant| File.delete(variant[:path]) if File.exist?(variant[:path]) }
          raise Liquid::Error, "ffmpeg failed for '#{source_rel}': #{stderr.strip}"
        end

        # Check if all requested files were created
        unless variants_to_generate.all? { |variant| File.file?(variant[:path]) }
          raise Liquid::Error, "ffmpeg did not create all requested outputs for '#{source_rel}'."
        end

        # Log which variants we generated
        variant_summary = variants_to_generate.map { |variant| "#{variant[:format]}" }.join(", ")
        filename = Pathname.new(source_rel).basename
        duration = (Time.now - started_at).round(2)
        Jekyll.logger.info("Responsive Video:", "generated #{filename} (#{variant_summary}) in #{duration} seconds.")
      end

      # Add the variants to the keep_files list and return them
      variants.each { |variant| Utils.add_keep_file(site, variant[:path]) }
      {
        dimensions: dimensions,
        variants: variants
      }
    rescue Errno::ENOENT
      raise Liquid::Error, "Unable to run ffmpeg. Install FFmpeg and make sure ffmpeg is available on PATH."
    end

    def get_output_path(site, source_rel, format, muted: false)
      source = Pathname.new(source_rel)
      profile = PROFILES.fetch(format)
      basename = source.basename(source.extname)
      audio_suffix = muted ? "-muted" : ""
      File.join(site.dest, source.dirname, "#{basename}-#{format}#{audio_suffix}.#{profile[:extension]}")
    end

    def build_ffmpeg_command(source_path, variants, config, muted: false, scale: 1.0)
      raise ArgumentError, "No variants to generate." if variants.empty?

      command = ["ffmpeg", "-y", "-i", source_path]

      filters = []
      filters << "scale=trunc(iw*#{scale}/2)*2:trunc(ih*#{scale}/2)*2" unless scale == 1.0
      filters << "null" if filters.empty?
      filter_stream_names = variants.each_index.map { |i| "[v#{i}]" }.join
      command.concat([
        "-filter_complex", 
        "[0:v]#{filters.join(",")},split=#{variants.size}#{filter_stream_names};",
      ])

      variants.each_with_index do |variant, index|
        profile = PROFILES.fetch(variant[:format])

        command.concat(["-map", "[v#{index}]"])
        command.concat(["-c:v", profile[:video_codec]])
        command.concat(muted ? ["-an"] : ["-c:a", profile[:audio_codec], "-b:a", profile[:audio_bitrate]])

        case variant[:format]
        when "h264"
          command.concat(["-preset", profile[:preset].to_s, "-crf", profile[:crf].to_s, "-pix_fmt", "yuv420p", "-movflags", "+faststart"])
        when "vp9"
          # -b:v 0 = enable CRF mode, -row-mt 1 = row-based multi-threading
          command.concat(["-b:v", "0", "-crf", profile[:crf].to_s, "-cpu-used", profile[:preset].to_s, "-row-mt", "1"])
        when "av1"
          command.concat(["-crf", profile[:crf].to_s, "-preset", profile[:preset].to_s])
        end

        command << variant[:path]
      end
      command
    end
  end
end
