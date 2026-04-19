require "jekyll"
require "listen"
require "rake/clean"
require "shellwords"
require "time"
require "yaml"

task :default => %i[js]

def listen_ignore_paths(base, options)
  [
    /_config\.ya?ml/,
    /_site/,
    /\.jekyll-cache/,
    /\.jekyll-metadata/,
    /assets\/js\/main\.min\.js$/
  ]
end

def listen_handler(base, options)
  site = Jekyll::Site.new(options)
  Jekyll::Command.process_site(site)
  proc do |modified, added, removed|
    t = Time.now
    c = modified + added + removed
    n = c.length
    relative_paths = c.map{ |p| Pathname.new(p).relative_path_from(base).to_s }

    js_sources = relative_paths.select do |path|
      path.start_with?("assets/js/") && path.end_with?(".js")
    end
    unless js_sources.empty?
      Rake::Task[JS_TARGET].reenable
      Rake::Task[JS_TARGET].invoke
    end

    print Jekyll.logger.message("Regenerating:", "#{relative_paths.join(", ")} changed... ")
    begin
      Jekyll::Command.process_site(site)
      puts "regenerated in #{Time.now - t} seconds."
    rescue => e
      puts "error:"
      Jekyll.logger.warn "Error:", e.message
      Jekyll.logger.warn "Error:", "Run jekyll build --trace for more information."
    end
  end
end

task :serve => %i[js] do
  base = Pathname.new('.').expand_path
  options = {
    "force_polling" => false,
    "serving"       => true,
  }

  options = Jekyll.configuration(options)

  ENV["LISTEN_GEM_DEBUGGING"] = "1"
  listener = Listen.to(
    base.join("_data"),
    base.join("_includes"),
    base.join("_layouts"),
    base.join("_sass"),
    base.join("assets"),
    options["source"],
    :ignore => listen_ignore_paths(base, options),
    :force_polling => options['force_polling'],
    &(listen_handler(base, options))
  )

  begin
    listener.start

    unless options["serving"]
      trap("INT") do
        listener.stop
        puts "     Halting auto-regeneration."
        exit 0
      end
      sleep
    end
  rescue ThreadError
    # You pressed Ctrl-C, oh my!
  end

  Jekyll::Commands::Serve.process(options)
end

JS_FILES = ["assets/js/vendor/jquery/jquery-3.6.0.js"] + Dir.glob("assets/js/plugins/*.js") + Dir.glob("assets/js/custom/*.js") + ["assets/js/_main.js"]
JS_TARGET = "assets/js/main.min.js"
task :js => JS_TARGET
file JS_TARGET => JS_FILES do |t|
  sh Shellwords.join(%w[npx uglifyjs -c --source-map -m -o] +
    [t.name] + t.prerequisites)
end
