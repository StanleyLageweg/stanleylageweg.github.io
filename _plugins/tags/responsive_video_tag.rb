# {% responsive_video "/assets/videos/demo.mp4" formats="h264,vp9,av1" controls="controls" class="responsive-video" %}
# {% responsive_video "/assets/videos/demo.mp4" start_time="10s" %}
# {% responsive_video "/assets/videos/demo.mp4" end_time="10000ms" %}
# {% responsive_video "/assets/videos/demo.mp4" duration="10000000us" %}
# {% responsive_video "/assets/videos/demo.mp4" speed="2" %}
# {% responsive_video "/assets/videos/demo.mp4" fps="60" %} (default fps = 30)
# {% responsive_video "/assets/videos/demo.mp4" crop="960:540:480:270" %} (crop="width:height:topLeftXCoordinate:topLeftYCoordinate")

require "cgi"
require_relative "../responsive_video"
require_relative "../utils"

module Jekyll
  module ResponsiveVideo
    class VideoTag < Liquid::Tag
      RESERVED_ATTRIBUTES = %w[source formats start_time end_time duration speed fps crop].freeze

      def initialize(tag_name, text, tokens)
        super
        @tokens = Utils.parse_attributes(text, default_attributes: ["source"])
      end

      def render(context)
        site = context.registers[:site]
        options = Utils.resolve_attributes(@tokens, context)
        options["muted"] = "muted" if options.key?("autoplay")
        sources = ResponsiveVideo.build_sources(
          Filepath.new(site, options.fetch("source")),
          Utils.parse_list(options["formats"]),
          muted: options.key?("muted"),
          start_time: options["start_time"],
          end_time: options["end_time"],
          duration: options["duration"],
          speed: options.key?("speed") ? Rational(options["speed"]) : nil,
          fps: options.key?("fps") ? Rational(options["fps"]) : 30r,
          crop: options["crop"],
        )

        attributes = Utils.parse_html_attributes(options, excluded_keys: RESERVED_ATTRIBUTES)
        attributes << %(width="#{sources[:data][:width]}") unless options.key?("width")
        attributes << %(height="#{sources[:data][:height]}") unless options.key?("height")

        source_tags = sources[:variants].map do |variant|
          source_attributes = [
            %(src="#{Utils.escape_html(variant[:path].public_url)}"),
            %(type="#{Utils.escape_html(variant[:path].mime_type)}")
          ]
          %(<source #{source_attributes.join(' ')}/>)
        end

        %(<video #{attributes.join(' ')}>#{source_tags.join}</video>)
      end

      private
    end
  end
end

Liquid::Template.register_tag("responsive_video", Jekyll::ResponsiveVideo::VideoTag)
