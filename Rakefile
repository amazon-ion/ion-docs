#version_string = `git describe --tag | cut  -d "-" -f 1,2 | tr - .`.chomp
#if version_string.empty?
#  version_string = '0'
#end

Version_string = "0.1"
Date_string = Time.now.strftime("%Y-%m-%d")

books = %w{IonSpec Demo}

image_files = Rake::FileList.new("src/images/*.png", "src/images/*.svg") do |fl|
  fl.exclude("~*")
  fl.exclude(/^scratch\//)
end


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
    task :images => target
  end

  task :prereqs => [:images]


  #=============================================================================
  # AsciiDoctor Processing

  def safe_system(app, *args)
    ok = system(app,  *args)
    raise "Could not find #{app}" if ok.nil?
    raise "#{app} failed with status #{$?.exitstatus}" unless $?.exitstatus == 0
  end

  def asciidoctor(*args)
    params = [
      "--attribute", "revnumber=#{Version_string}",
      "--attribute", "revdate=#{Date_string}",
      "--trace",
      "--verbose",
    ]
    safe_system 'bundle', 'exec', 'asciidoctor', *params, *args
  end


  def adoc_to_html(adoc, html)
    puts "Converting #{adoc} to HTML..."
    asciidoctor('--backend', 'html5',
                '--out-file', html,
                adoc)
  end

  def adoc_to_xml(adoc, xml)
    puts "Converting #{adoc} to DocBook XML..."
    asciidoctor('--backend', 'docbook',
                '--out-file', xml,
                adoc)
  end

  def adoc_to_pdf(adoc, pdf)
    puts "Converting #{adoc} to PDF..."

    theming = %w(-a pdf-themesdir=src/themes -a pdf-theme=basic -a pdf-fontsdir=fonts)
    stem = %w(-r asciidoctor-mathematical -a mathematical-format=svg)
    pdf_params = %w(-a compress)

    asciidoctor(*theming, *stem, *pdf_params,
                '--require', 'asciidoctor-pdf',
                '--backend', 'pdf',
                '--out-file', pdf,
                adoc)
  end

  def xml_to_pdf(xml)
    puts "Converting #{xml} to PDF..."

    # See our dblatex/README.md for explanation.

    # https://www.mankier.com/1/xmlto
    xmlto_params = [
      "--skip-validation",
      # "-vv",                       # Enables --verbose for dblatex
    ]

    # https://www.mankier.com/1/dblatex
    dblatex_params = [
      "--param=latex.encoding=utf8",
      "--xsl-user=/workspace/dblatex/xsl/ion.xsl",
      "--texstyle=/workspace/dblatex/ion.sty",
      "--texpost=/workspace/dblatex/postprocess.sh",
      # "--quiet",                  # Less verbose, only error messages
      # "--verbose",                # Show the running commands
      "--debug",                  # Keep the /tmp subdir with tex files
    ]

    safe_system('xmlto',  *xmlto_params,
                '--with-dblatex',
                '-p', dblatex_params.join(' '),
                '-o', 'build',
                'pdf',
                xml)
  end


  #=============================================================================
  # Generate tasks for each book

  books.each do |book|
    adoc = "src/#{book}.adoc"
    xml  = "build/#{book}.xml"
    pdf  = "build/#{book}.pdf"
    html = "build/#{book}.html"

    file xml => [:prereqs, adoc] do
      adoc_to_xml adoc, xml
    end

    file html => [:prereqs, adoc] do
      adoc_to_html adoc, html
    end

    file pdf => [:prereqs, xml] do
      xml_to_pdf xml
    end
  end


  task :html    => "build/IonSpec.html"
  task :pdf     => "build/IonSpec.pdf"
  task :docbook => "build/IonSpec.xml"

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

desc "Build the book as HTML"
task :html  => "spec:html"

desc "Build the book as PDF"
task :pdf   => "spec:pdf"

desc "Build the book in all formats"
task :build => "spec:build"

task :watch => "spec:watch"

desc "Build the demo document for checking rendering."
task :demo  => "build/Demo.pdf"
