#version_string = `git describe --tag | cut  -d "-" -f 1,2 | tr - .`.chomp
#if version_string.empty?
#  version_string = '0'
#end

version_string = "0.1"
date_string = Time.now.strftime("%Y-%m-%d")
params = "--attribute revnumber='#{version_string}' --attribute revdate='#{date_string}'"

image_files = Rake::FileList.new("src/images/*.png", "src/images/*.svg") do |fl|
  fl.exclude("~*")
  fl.exclude(/^scratch\//)
end

doc_name = "Ion-Specification"

namespace :spec do
  directory 'build/images'

  desc 'copy images to build dir'
  task :images => 'build/images'

  image_files.each do |source|
    target = source.sub(/^src\/images/, 'build/images')
    file target => source do
      cp source, target, :verbose => true
      if File.extname(target) == ".png"
        `pngquant -f #{target}`
      end
    end
    desc "copies all data files"
    task :images => target
  end

  task :prereqs => [:images]
  
  desc 'build basic spec formats'
  task :html => :prereqs do
    begin
      puts "Converting to HTML..."
      `bundle exec asciidoctor -b html5 #{params} src/main.adoc -o build/#{doc_name}.html`
    end
  end

  task :pdf => :prereqs do
    begin
      theming = "-a pdf-themesdir=src/themes -a pdf-theme=basic -a pdf-fontsdir=fonts"
      stem = "-r asciidoctor-mathematical -a mathematical-format=svg"
      pdf_params = "-a compress"
      puts "Converting to PDF..."
      `bundle exec asciidoctor-pdf -v #{params} #{theming} #{stem} #{pdf_params} src/main.adoc -o build/#{doc_name}.pdf --trace`
    end
  end

  task :docbook => :prereqs do
    begin
      puts "Converting to Docbook..."
      `bundle exec asciidoctor -b docbook #{params} src/main.adoc -o build/#{doc_name}.xml`
    end
  end

  task :build => [:html, :pdf, :docbook]

  task watch: [:build] do
    begin
      `bundle exec guard`
    end
  end

  require 'rake/clean'
  CLEAN.include('build')
  CLOBBER.include('build')
end

task :default => "spec:build"

task :clean => "spec:clean"
task :html  => "spec:html"
task :pdf   => "spec:pdf"
task :build => "spec:build"
task :watch => "spec:watch"
