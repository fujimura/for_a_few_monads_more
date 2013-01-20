require 'watchr'

task default: [:compile]

desc "Compile file to HTML5 slide"
task :compile do
  Dir.entries('./').grep(/\.lhs$/).each do |file|
    name, = file.partition(/\..*$/)
    to = [name, '.', 'html'].join

    `pandoc -t slidy -s #{file} -o #{to}`
  end
end

desc "Open files"
task :open do
  Dir.glob("./*.html").each do |file|
    `open #{file}`
  end
end

# Won't work ATM
#
desc "Watch files. If file was changed, compile it"
task :watch do
  watch '^.*\.lhs$' do |md|
    print "Compiling '#{md[0]}'..."
    Rake::Task[:compile].invoke
    puts "Done (#{Time.now})"
  end
end

def watch re
  script = Watchr::Script.new
  script.watch re do |md|
    yield md
  end
  handler = Watchr.handler.new
  controller = Watchr::Controller.new(script, handler)
  controller.run
end
