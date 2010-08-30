require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights
  attr_accessor :container, :manifest, :spine, :navigation, :base

  def initialize(filepath)
    @filepath = filepath
    parse
  end

  def save(directory)
    tmp = Dir.mktmpdir("folio-zip-")
    epubFilename = "#{directory}/#{@title}.epub"
    FileUtils.mkdir_p(["#{tmp}/META-INF", "#{tmp}/OEBPS"])
    FileUtils.cp(NSBundle.mainBundle.pathForResource("mimetype", ofType:nil), "#{tmp}/mimetype")
    @container.save(tmp)
    @navigation.save(tmp)
    writeOPF(tmp)
    system("cd '#{tmp}'; zip -X0 '#{epubFilename}' mimetype")
    system("cd '#{tmp}'; zip -X9urD '#{epubFilename}' *")
  end

  private

  def parse
    unzip
    @container  = Container.new(self)
    parseMetadata
    @manifest   = Manifest.new(self)
    @spine      = Spine.new(self)
    @navigation = Navigation.new(self)
  end

  def unzip
    @base = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@base}' '#{@filepath}'")
  end

  def parseMetadata
    @container.opfDoc.elements.each("/package/metadata/*") do |e|
      case e.name
      when 'title'
        @title = e.text
      when 'publisher'
        @publisher = e.text
      when 'creator'
        @creator = e.text
      when 'date'
        @date = e.text
      when 'language'
        @language = e.text
      when 'description'
        @description = e.text
      when 'rights'
        @rights = e.text
      when 'identifier'
        @identifier = e.text
      when 'subject'
        @subject = e.text
      else
        #puts "Unparsed metadata element: #{e}" if e.name.strip.size != 0
      end
    end
  end

  def writeOPF(dest)
    File.open("#{dest}/OEBPS/content.opf", "w") do |f|
      f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      f.puts "<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookID\" version=\"2.0\">"
      f.puts "  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:opf=\"http://www.idpf.org/2007/opf\">"
      f.puts "    <dc:title>#{@title}</dc:title>"
      f.puts "    <dc:creator opf:role=\"aut\">#{@creator}</dc:creator>"
      f.puts "    <dc:description>#{@description}</dc:description>"
      f.puts "    <dc:publisher>#{@publisher}</dc:publisher>"
      f.puts "    <dc:language>#{@language}</dc:language>"
      f.puts "    <dc:identifier id=\"BookID\" opf:scheme=\"UUID\">#{@identifier}</dc:identifier>"
      f.puts "  </metadata>"
      f.puts "  <manifest>"
      f.puts "    <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>"
      @manifest.each do |item|
        if item.id && item.manifestable?
          f.puts "    <item id=\"#{item.id}\" href=\"#{item.href}\" media-type=\"#{item.mediaType}\"/>"
          FileUtils.mkdir_p(File.dirname("#{dest}/#{item.href}"))
          puts "#{@base}/#{@container.root}/#{item.href}"
          FileUtils.cp("#{@base}/#{item.href}", "#{dest}/OEBPS/#{item.href}")
        end
      end
      f.puts "  </manifest>"
      f.puts "  <spine toc=\"ncx\">"
      @spine.each do |item|
        f.puts "    <itemref idref=\"#{item.id}\"/>"
      end
      f.puts "  </spine>"
      f.puts "</package>"
    end
  end

  def raiseParseException(reason)
    raise "Book #{@filepath} cannot be opened because #{reason}."
  end

end
