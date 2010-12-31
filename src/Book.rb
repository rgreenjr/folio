require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"
require "open-uri"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :navigation, :manifest, :spine, :container, :metadata, :guide
  attr_accessor :filepath, :unzippath, :edited

  def initialize(filepath)
    @filepath = filepath
    @unzippath = Dir.mktmpdir("folio-unzip-")
    system("unzip -q -d '#{@unzippath}' \"#{@filepath}\"")
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
  
  def basename
    File.basename(@filepath)
  end
  
  def save
    tmp = Dir.mktmpdir("folio-zip-")
    # system("open #{tmp}")
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.root)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.root, "content.opf"), "w") {|f| f.puts opf_xml}
    system("cd '#{tmp}'; zip -qX0 '#{@filepath}' mimetype")
    system("cd '#{tmp}'; zip -qX9urD '#{@filepath}' *")
    FileUtils.rm_rf(tmp)
  end  
  
  def saveAs(filepath)
    filepath = filepath + '.epub' unless File.extname(filepath) == '.epub'
    @filepath = filepath
    save
  end
  
  def close
    FileUtils.rm_rf(@unzippath)
  end
  
  def relativePathFor(filepath)
    filepath.gsub(@unzippath, '')
  end
  
  private
  
  def opf_xml
    book = self
    ERB.new(Bundle.template("content.opf")).result(binding)
  end
    
end
