require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"
require "open-uri"

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
    system("open #{tmp}")
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.root)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.root, "content.opf"), "w") {|f| f.puts opf_xml}
    epub = File.join(directory, "#{title.sanitize}.epub")
    system("cd '#{tmp}'; zip -qX0 '#{epub}' mimetype")
    system("cd '#{tmp}'; zip -qX9urD '#{epub}' *")
  end

  def opf_xml
    book = self
    ERB.new(Bundle.template("content.opf")).result(binding)
  end
  
  def description
    @metadata.description
  end

  def method_missing(method, *args)
    if @metadata.respond_to?(method.to_sym)
      @metadata.send(method, *args)
    else
      super
    end
  end
    
end
