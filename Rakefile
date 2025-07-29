#version_string = `git describe --tag | cut  -d "-" -f 1,2 | tr - .`.chomp
#if version_string.empty?
#  version_string = '0'
#end

Version_string = "0.1"
Date_string = Time.now.strftime("%Y-%m-%d")

books = %w{Semantics Demo}


namespace :spec do

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


  def adoc_to_xml(adoc, xml)
    puts "Converting #{adoc} to DocBook XML..."
    asciidoctor('--backend', 'docbook',
                '--out-file', xml,
                adoc)
  end


  def xml_to_pdf(xml)
    puts "Converting #{xml} to PDF..."

    book = File.basename(xml, '.xml')

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
      "--texinputs=/workspace/dblatex/tex",
      "--texstyle=ion",
      "--texpost=/workspace/dblatex/postprocess.sh",
      # "--quiet",                  # Less verbose, only error messages
      # "--verbose",                # Show the running commands
      "--debug",                  # Keep the /tmp subdir with tex files
    ]

    # Book-specific XSL stylesheet (overrides the above default)
    xsl = "/workspace/dblatex/xsl/#{book}.xsl"
    dblatex_params << "--xsl-user=#{xsl}" if File.readable?(xsl)

    # Book-specific LaTeX style (overrides the above default)
    sty = "/workspace/dblatex/tex/#{book}.sty"
    dblatex_params << "--texstyle=#{book}" if File.readable?(sty)

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

    file xml => [adoc] do
      adoc_to_xml adoc, xml
    end

    file pdf => [xml] do
      xml_to_pdf xml
    end

    task :docbook => xml
    task :pdf     => pdf
  end


  task :build => [:pdf, :docbook]

  task watch: [:build] do
    begin
      `bundle exec guard`
    end
  end

  require 'rake/clean'
  CLEAN.include('build')
  CLOBBER.include('build')
end

task :default => "spec:pdf"

task :clean => "spec:clean"

desc "Build the book as PDF"
task :pdf   => "spec:pdf"

desc "Build the book in all formats"
task :build => "spec:build"

task :watch => "spec:watch"

desc "Build the demo document for checking rendering."
task :demo  => "build/Demo.pdf"
