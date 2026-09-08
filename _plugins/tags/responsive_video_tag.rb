# {% responsive_video "/assets/videos/demo.mp4" formats="h264,vp9,av1" controls="controls" class="responsive-video" %}

require "cgi"
require_relative "../responsive_video"
require_relative "../utils"

module Jekyll
  module ResponsiveVideo
    class VideoTag < Liquid::Tag
      RESERVED_ATTRIBUTES = %w[source formats].freeze

      def initialize(tag_name, text, tokens)
        super
        @tokens = Utils.parse_attributes(text, default_attributes: ["source"])
      end

      def render(context)
        site = context.registers[:site]
        config = ResponsiveVideo.config_for(site)
        options = Utils.resolve_attributes(@tokens, context)
        source_rel = options.fetch("source")
        source_path = Utils.get_source_path(site, source_rel)
        options["muted"] = "muted" if options.key?("autoplay")
        muted = options.key?("muted")
        formats = ResponsiveVideo.parse_formats(options["formats"] || config["default_formats"])
        sources = ResponsiveVideo.build_sources(site, source_path, source_rel, formats, config, muted: muted)

        attributes = Utils.parse_html_attributes(options, excluded_keys: RESERVED_ATTRIBUTES)
        attributes << %(width="#{sources[:dimensions][:width]}") unless options.key?("width")
        attributes << %(height="#{sources[:dimensions][:height]}") unless options.key?("height")

        source_tags = sources[:variants].map do |variant|
          source_attributes = [
            %(src="#{Utils.escape_html(Utils.public_url(site, variant[:path]))}"),
            %(type="#{Utils.escape_html(variant[:mime_type])}")
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
