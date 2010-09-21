require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights
  attr_accessor :container, :manifest, :spine, :guide, :navigation, :path

  def initialize(filepath)
    @filepath = filepath
    parse
  end

  def save(directory)
    tmp = Dir.mktmpdir("folio-zip-")
    `open #{tmp}`
    epubFilename = "#{directory}/#{@title}.epub"
    FileUtils.cp(NSBundle.mainBundle.pathForResource("mimetype", ofType:nil), "#{tmp}/mimetype")
    @container.save(tmp)
    dest = File.join(tmp, @container.root)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open("#{tmp}/#{@container.root}/content.opf", "w") {|f| f.puts to_xml}
    system("cd '#{tmp}'; zip -qX0 '#{epubFilename}' mimetype")
    system("cd '#{tmp}'; zip -qX9urD '#{epubFilename}' *")
  end

  private

  def parse
    unzip
    @container  = Container.new(self)
    parseMetadata
    @manifest   = Manifest.new(self)
    @spine      = Spine.new(self)
    @guide      = Guide.new
    @navigation = Navigation.new(self)
  end

  def unzip
    @path = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@path}' '#{@filepath}'")
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
  
  def to_xml
    @book = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("content.opf", ofType:"erb"))).result(binding)
  end

  def raiseParseException(reason)
    raise "Book #{@filepath} cannot be opened because #{reason}."
  end

end
