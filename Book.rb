require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights
  attr_accessor :container, :manifest, :spine, :layout
  attr_accessor :base

  def initialize(filepath)
    @spine = []
    @filepath = filepath
    @base = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@base}' '#{@filepath}'")
    @container = Container.new(self)
    @manifest  = Manifest.new(self)
    @spine     = Spine.new(self)
    @package   = Package.new(self)
    @layout    = Layout.new(self)
  end

  def save(directory)
    tmp = Dir.mktmpdir("folio-zip-")
    epubFilename = "#{directory}/#{@title}.epub"
    FileUtils.mkdir_p(["#{tmp}/META-INF", "#{tmp}/OEBPS"])
    FileUtils.cp(NSBundle.mainBundle.pathForResource("mimetype", ofType:nil), "#{tmp}/mimetype")
    @container.save(tmp)
    @navMap.save(tmp)
    @package.save(self, @base, tmp)
    system("cd '#{tmp}'; zip -X0 '#{epubFilename}' mimetype")
    system("cd '#{tmp}'; zip -X9urD '#{epubFilename}' *")
  end
  
  private
  
  def raiseParseException(reason)
    raise "Book #{@filepath} cannot be opened because #{reason}."
  end

end
