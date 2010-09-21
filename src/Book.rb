require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"
require 'open-uri'

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :container, :metadata, :manifest, :spine, :guide, :navigation, :path

  def initialize(filepath)
    @path = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@path}' '#{filepath}'")
    @container  = Container.new(self)
    @metadata   = Metadata.new(self)
    @manifest   = Manifest.new(self)
    @spine      = Spine.new(self)
    @guide      = Guide.new(self)
    @navigation = Navigation.new(self)
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

  def to_xml
    @book = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("content.opf", ofType:"erb"))).result(binding)
  end

  def method_missing(method, *args)
    if @metadata.respond_to?(method.to_sym)
      @metadata.send(method, *args)
    else
      super
    end
  end
    
end
