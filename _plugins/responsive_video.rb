require "open3"

require "jekyll"
require_relative "utils"

module Jekyll
  module ResponsiveVideo
    CONFIG = {
      formats: ["av1", "vp9", "h264"]
    }.freeze

    # crf = Constant Rate Factor, tradeff between quality and file size. Lower values increase both quality and file size.
    # preset / cpu-used = tradeoff between encoding speed and file size. Lower values decrease file size but increase encoding time.
    # -b:a = Audio bitrate
    PROFILES = {
      "h264" => {
        extension: "mp4",
        video_codec: "libx264",
        audio_codec: "aac",
        video_options: {
          "preset" => "slow", # ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow, placebo.
          "crf" => 27, # 0 to 51, 0 = lossless, 20 to 23 = balanced, 28 to 30 = small file.
          "pix_fmt" => "yuv420p",
          "movflags" => "+faststart",
        }.freeze,
        audio_options: {
          "b:a" => "128k", # 128k to 192k = recommended for web
        }.freeze,
      }.freeze,
      "vp9" => {
        extension: "webm",
        video_codec: "libvpx-vp9",
        audio_codec: "libopus",
        video_options: {
          "b:v" => 0, # Enable CRF mode
          "crf" => 35, # 0 to 63, 25 to 31 = balanced, 35 to 40 = small file.
          "cpu-used" => 3, # -8 to 8, 2 to 4 = recommended
          "row-mt" => 1, # Enable ow-based multi-threading
        }.freeze,
        audio_options: {
          "b:a" => "96k", # 64k to 128k = recommended for web
        }.freeze,
      }.freeze,
      "av1" => {
        extension: "webm",
        video_codec: "libsvtav1",
        audio_codec: "libopus",
        video_options: {
          "preset" => 6, # -2 to 13, 2 to 6 = recommended
          "crf" => 40, # 0 to 63, 28 to 32 = balanced, 38 to 45 = small file.
        }.freeze,
        audio_options: {
          "b:a" => "96k", # 64k to 128k = recommended for web
        }.freeze,
      }.freeze
    }.freeze

    module_function

    def get_cache_key
      profiles = Marshal.load(Marshal.dump(PROFILES))
      profiles["vp9"][:video_options].delete("row-mt")
      Utils.cache_key(profiles)
    end

    def get_optional_cache_key
      Utils.cache_key(CONFIG)
    end

    def parse_formats(formats)
      formats = formats.map(&:downcase).uniq
      formats = CONFIG[:formats] if formats.empty?
      invalid = formats - PROFILES.keys
      raise ArgumentError, "Unsupported video format(s): #{invalid.join(', ')}." unless invalid.empty?
      formats
    end

    def get_data(source_path)
      stdout, stderr, status = Open3.capture3(
        "ffprobe",
        "-v", "error",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height,r_frame_rate",
        "-of", "json",
        source_path
      )
      raise Liquid::Error, "ffprobe failed for '#{source_path.relative_path}': #{stderr.strip}" unless status.success?

      stream = JSON.parse(stdout).fetch("streams").first
      {
        width: Integer(stream.fetch("width")), 
        height: Integer(stream.fetch("height")),
        fps: Rational(stream.fetch("r_frame_rate")),
      }
    rescue Errno::ENOENT
      raise Liquid::Error, "Unable to run ffprobe. Install FFmpeg and make sure ffprobe is available on PATH."
    rescue JSON::ParserError, KeyError, TypeError, ArgumentError => error
      raise Liquid::Error, "Unable to read video metadata for '#{source_path.relative_path}': #{error.message}"
    end

    def build_sources(source_path, formats, muted: false, start_time: nil, end_time: nil, duration: nil, speed: nil, fps: nil, crop: nil)
      raise ArgumentError, "end_time and duration are mutualy exclusive (#{source_path.relative_path})" if end_time && duration
      data = get_data(source_path)
      scale = 1r
      max_size = ([data[:width], data[:height]] + (crop&.split(":", 2)&.map(&:to_i) || [])).max
      if max_size > 1920
        scale = 1920r / max_size
        data[:width] = (data[:width] * scale / 2).floor * 2
        data[:height] = (data[:height] * scale / 2).floor * 2
      end
      data[:fps] *= speed if speed
      if fps
        if data[:fps] - fps > 5
          data[:fps] = fps
        else
          fps = nil
        end
      end

      # Determine which variants we need
      formats = parse_formats(formats)
      variants = formats.map do |format|
        path_suffix = "-#{format}"
        path_suffix += "-muted" if muted
        path_suffix += "-ss-#{start_time.gsub("/[.:]/", "-")}" if start_time
        path_suffix += "-to-#{end_time.gsub("/[.:]/", "-")}" if end_time
        path_suffix += "-t-#{duration.gsub("/[.:]/", "-")}" if duration
        path_suffix += "-crop-#{crop.gsub(":", "-")}" if crop
        path_suffix += "-speed-#{speed.to_f.round(3).to_s.gsub(".", "-")}" if speed
        path_suffix += "-fps-#{data[:fps].to_f.round(3).to_s.gsub(".", "-")}" if fps
        extension = PROFILES.fetch(format)[:extension]
        {
          format: format,
          path: OutputFilepath.new(source_path, suffix: path_suffix, extension: extension)
        }
      end

      # Determine which variants need to be generated
      variants_to_generate = variants.reject { |variant| variant[:path].up_to_date? }
      variants_to_generate.each { |variant| variant[:path].make_directory }

      # Generate the variants using ffmpeg
      unless variants_to_generate.empty?
        Utils.log_duration("Responsive Video:") do
          input_options = {}
          input_options["ss"] = start_time if start_time
          input_options["to"] = end_time if end_time
          input_options["t"] = duration if duration
          command_builder = FFmpegBuilder.new(source_path.path, input_options: input_options)

          variants_to_generate.each do |variant|
            video_filters = []
            video_filters << "setpts=#{1/speed}*PTS" if speed
            video_filters << "fps=#{data[:fps]}" if fps
            video_filters << "crop=#{crop}" if crop
            video_filters << "scale=#{data[:width]}:#{data[:height]}" unless scale == 1r

            audio_filters = []
            audio_filters << "atempo=#{speed}" if speed

            profile = PROFILES.fetch(variant[:format])

            command_builder.add_output(variant[:path],
              video_codec: profile[:video_codec],
              audio_codec: profile[:audio_codec],
              video_filters: video_filters,
              audio_filters: audio_filters,
              video_options: profile[:video_options],
              audio_options: profile[:audio_options],
              muted: muted,
            )

            variant[:path].make_directory
          end

          _stdout, stderr, status = Open3.capture3(*command_builder.generate)
          unless status.success?
            variants_to_generate.each { |variant| variant[:path].delete }
            raise Liquid::Error, "ffmpeg failed for '#{source_path.relative_path}': #{stderr.strip}"
          end

          # Check if all requested files were created
          unless variants_to_generate.all? { |variant| variant[:path].exist? }
            raise Liquid::Error, "ffmpeg did not create all requested outputs for '#{source_path.relative_path}'."
          end

          # Log which variants we generated
          variant_summary = variants_to_generate.map { |variant| "#{variant[:format]}" }.join(", ")
          "generated #{source_path.relative_path} [#{variant_summary}]"
        end
      end

      # Add the variants to the keep_files list and return them
      variants.each { |variant| variant[:path].add_keep_file }
      {
        data: data,
        variants: variants
      }
    end
  end
end
