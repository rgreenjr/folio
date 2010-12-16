require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"
require "open-uri"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :navigation, :manifest, :spine
  attr_accessor :container, :metadata, :guide, :path, :edited

  def initialize(filepath)
    @path = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@path}' '#{filepath}'")
    @container  = Container.new(self)
    @manifest   = Manifest.new(self)
    @metadata   = Metadata.new(self)
    @spine      = Spine.new(self)
    @guide      = Guide.new(self)
    @navigation = Navigation.new(self)
  end
  
  def edited?
    @edited
  end
  
  def save(directory)
    tmp = Dir.mktmpdir("folio-zip-")
    # system("open #{tmp}")
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.root)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.root, "content.opf"), "w") {|f| f.puts opf_xml}
    epub = File.join(directory, "#{metadata.title.sanitize}.epub")
    system("cd '#{tmp}'; zip -qX0 '#{epub}' mimetype")
    system("cd '#{tmp}'; zip -qX9urD '#{epub}' *")
    FileUtils.rm_rf(tmp)
  end
  
  def close
    FileUtils.rm_rf(@path)
  end
  
  private
  
  def opf_xml
    book = self
    ERB.new(Bundle.template("content.opf")).result(binding)
  end
    
end
