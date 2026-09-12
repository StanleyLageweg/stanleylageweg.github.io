# Builds ffmpeg commands which take a single input file and create multiple output files with various filters and codecs
# The filter pipelines of the outputs are automatically merged to together, where possible

class FFmpegBuilder
  class Node
    attr_accessor :filter, :children, :outputs

    def initialize(filter)
      @filter = filter
      @children = []
      @outputs = []
    end
  end

  class Output
    attr_accessor :filename, :video_codec, :audio_codec, :video_filters, :audio_filters, :video_options, :audio_options, :muted

    def initialize(filename, video_codec, audio_codec, video_filters, audio_filters, video_options, audio_options, muted)
      @filename = filename
      @video_codec = video_codec
      @audio_codec = audio_codec
      @video_filters = video_filters.compact.reject(&:empty?)
      @audio_filters = audio_filters.compact.reject(&:empty?)
      @video_options = video_options || {}
      @audio_options = audio_options || {}
      @muted = muted
    end
  end

  def initialize(input_file, input_options: {})
    @input_file = input_file
    @input_options = input_options
    @outputs = []
    @video_root = Node.new(nil)
    @audio_root = Node.new(nil)
  end

  def add_output(filename, video_codec: nil, audio_codec: nil, video_filters: [], audio_filters: [], video_options: {}, audio_options: {}, muted: false)
    output = Output.new(filename, video_codec, audio_codec, video_filters, audio_filters, video_options, audio_options, muted)
    @outputs << output
    
    insert_chain(@video_root, output.video_filters, output)
    insert_chain(@audio_root, output.audio_filters, output) unless muted
  end

  def generate
    cmd = ["ffmpeg"]
    
    # Add the input options
    @input_options.each do |key, value|
      if value == true
        cmd << "-#{key}"
      elsif value != false && !value.nil?
        cmd << "-#{key}" << value.to_s
      end
    end

    cmd.push("-i", @input_file)

    # Build the filter pipeline graph
    state = { 
      counter: 0, 
      maps: Hash.new { |hash, key| hash[key] = {} } 
    }
    filter_complex_parts = []
    build_graph(@video_root, "[0:v]", filter_complex_parts, :v, state)
    state[:counter] = 0
    build_graph(@audio_root, "[0:a]", filter_complex_parts, :a, state)
    cmd.push("-filter_complex", filter_complex_parts.join(';')) if filter_complex_parts.any?

    @outputs.each do |output|
      # Map the video
      if (video_label = state[:maps][output][:v])
        video_label = "0:v" if video_label == "[0:v]"
        cmd << "-map" << video_label
      end
      
      # Map the audio
      if !output.muted && (audio_label = state[:maps][output][:a])
        audio_label = "0:a" if audio_label == "[0:a]"
        cmd << "-map" << audio_label
      end

      # Add the video codec
      cmd << "-c:v" << output.video_codec if output.video_codec
      
      # Add the audio codec
      if output.muted
        cmd << "-an"
      elsif output.audio_codec
        cmd << "-c:a" << output.audio_codec
      end

      # Add the video and audio options
      [output.video_options, (output.audio_options unless output.muted)].compact.each do |options|
        options.each do |key, value|
          if value == true
            cmd << "-#{key}"
          elsif value != false && !value.nil?
            cmd << "-#{key}" << value.to_s
          end
        end
      end

      cmd << output.filename
    end

    cmd
  end

  private

  def insert_chain(root, filters, output)
    current = root
    filters.each do |f|
      child = current.children.find { |c| c.filter == f }
      unless child
        child = Node.new(f)
        current.children << child
      end
      current = child
    end
    current.outputs << output
  end

  def build_graph(node, input_label, filter_parts, type, state)
    current = node
    chain_filters = []

    loop do
      # Add the current node's filter to the chain
      chain_filters << current.filter if current.filter

      consumers_count = current.children.size + current.outputs.size
      break if consumers_count <= 0

      # Chain diverges: Split
      if consumers_count > 1
        split_filter = (type == :v) ? "split=#{consumers_count}" : "asplit=#{consumers_count}"
        chain_filters << split_filter
        
        state[:counter] += 1
        split_labels = consumers_count.times.map { |i| "[#{type}#{state[:counter]}_s#{i}]" }
        
        # Output the accumulated chain (e.g. "[0:v]scale=1080,split=2[v1_s0][v1_s1]")
        filter_parts << "#{input_label}#{chain_filters.join(',')}#{split_labels.join}"
        
        # Route outputs
        label_idx = 0
        current.outputs.each do |output|
          state[:maps][output][type] = split_labels[label_idx]
          label_idx += 1
        end
        
        # Recurse for remaining branch children
        current.children.each do |child|
          build_graph(child, split_labels[label_idx], filter_parts, type, state)
          label_idx += 1
        end
        
        break
      end

      # Chain ends at a single output
      if current.outputs.any?
        output = current.outputs.first
        
        if chain_filters.any?
          state[:counter] += 1
          output_label = "[#{type}#{state[:counter]}]"
          filter_parts << "#{input_label}#{chain_filters.join(',')}#{output_label}"
          state[:maps][output][type] = output_label
        else
          # Edge case: No filters were applied at all, just map the raw input stream
          state[:maps][output][type] = input_label
        end
        
        break
      end

      # Chain continues without splitting
      current = current.children.first
    end
  end
end
