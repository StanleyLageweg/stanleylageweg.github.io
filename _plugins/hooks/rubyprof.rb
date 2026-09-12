require "fileutils"
require "ruby-prof"
require "launchy"

module JekyllRubyProfOptions
  def add_build_options(command)
    super
    command.option "ruby-prof", "--ruby-prof", "Perform ruby-prof performance profiling"
  end
end

Jekyll::Command.singleton_class.prepend(JekyllRubyProfOptions)

module Jekyll
  module JekyllRubyProf
    PROFILE = RubyProf::Profile.new.freeze

    module_function

    def start(site)
      if site.config['ruby-prof']
        PROFILE.start
        Jekyll.logger.info "Ruby-prof:", "Profiling started..."
      end
    end

    def stop(site)
      if site.config['ruby-prof'] == true
        result = PROFILE.stop

        FileUtils.mkdir_p('ruby-prof')
        suffix = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
        fileName = "ruby-prof/flame_graph_#{suffix}.html"

        printer = RubyProf::FlameGraphPrinter.new(result)
        printer.print(File.open(fileName, "w"))
        Jekyll.logger.info "Ruby-prof:", "Saved flame graph to #{fileName}"
        Utils.silence_output do
          Launchy.open("file://#{File.expand_path(fileName)}")
        end
      end
    end
  end
end
