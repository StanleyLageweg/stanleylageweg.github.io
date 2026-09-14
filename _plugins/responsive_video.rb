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
      profiles.transform_values! do |profile|
        profile = profile.dup
        video = profile.delete(:video_options) || {}
        audio = profile.delete(:audio_options) || {}
        (profile.merge(video).merge(audio))
      end
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

    def build_sources(site, source_path, formats, muted: false, start_time: nil, end_time: nil, duration: nil, speed: nil, fps: nil, crop: nil)
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

      input_options = {}
      input_options["ss"] = start_time if start_time
      input_options["to"] = end_time if end_time
      input_options["t"] = duration if duration

      video_filters = []
      video_filters << "setpts=#{1/speed}*PTS" if speed
      video_filters << "fps=#{data[:fps]}" if fps
      video_filters << "crop=#{crop}" if crop
      video_filters << "scale=#{data[:width]}:#{data[:height]}" unless scale == 1r

      audio_filters = []
      audio_filters << "atempo=#{speed}" if speed

      # Determine which variants we need
      formats = parse_formats(formats)
      configs = formats.map do |format|
        PROFILES.fetch(format).merge({
          format: format,
          input_options: input_options,
          video_filters: video_filters,
          audio_filters: audio_filters,
          muted: muted,
        })
      end

      outputs = CacheUtils.get_or_generate(site, source_path, CacheUtils::VIDEO_CACHE, configs) do |to_generate|
        Utils.log_duration("Responsive Video:") do
          command_builder = FFmpegBuilder.new(source_path.path, input_options: input_options)
          to_generate.each do |output|
            raise "input_options changed" if output[:config][:input_options] != input_options
            command_builder.add_output(output[:path],
              video_codec: output[:config][:video_codec],
              audio_codec: output[:config][:audio_codec],
              video_filters: output[:config][:video_filters],
              audio_filters: output[:config][:audio_filters],
              video_options: output[:config][:video_options],
              audio_options: output[:config][:audio_options],
              muted: output[:config][:muted],
            )
          end

          _stdout, stderr, status = Open3.capture3(*command_builder.generate)
          unless status.success?
            to_generate.each { |output| output[:path].delete }
            raise Liquid::Error, "ffmpeg failed for '#{source_path.relative_path}': #{stderr.strip}"
          end

          generated_outputs = to_generate.map { |output| "#{output[:config][:format]}" }
          "generated #{source_path.relative_path} [#{generated_outputs.join(", ")}]"
        end
      end

      {
        data: data,
        paths: outputs.map { |output| output[:path] }
      }
    end
  end
end
