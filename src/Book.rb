require "rexml/document"
require "fileutils"
require "erb"
require "tempfile"
require "open-uri"
require "cgi"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book < NSDocument

  attr_reader :controller, :unzippath
  attr_reader :navigation, :manifest, :spine, :container, :metadata, :guide
  
  def init
    super
    @metadata = Metadata.new
    @container = Container.new
    @manifest = Manifest.new
    @spine = Spine.new
    @navigation = Navigation.new
    @guide = Guide.new
    self
  end

  def readFromURL(absoluteURL, ofType:inTypeName, error:outError)
    @unzippath = Dir.mktmpdir("folio-unzip-")
    runCommand("unzip -q -d '#{@unzippath}' \"#{absoluteURL.path}\"")
    @container  = Container.new(self)
    @manifest   = Manifest.new(self)
    @metadata   = Metadata.new(self)
    @spine      = Spine.new(self)
    @guide      = Guide.new(self)
    @navigation = Navigation.new(self)
    true
  rescue Exception => exception
    info = { NSLocalizedFailureReasonErrorKey => exception.message }
    outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:info))
    false
  end

  def writeToURL(absoluteURL, ofType:inTypeName, error:outError)
    tmp = Dir.mktmpdir("folio-zip-")
    # system("open #{tmp}")
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.root)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.root, "content.opf"), "w") {|f| f.puts opfXML}
    runCommand("cd '#{tmp}'; zip -qX0 ./folio-book.epub mimetype")
    runCommand("cd '#{tmp}'; zip -qX9urD ./folio-book.epub *")
    FileUtils.mv(File.join(tmp, 'folio-book.epub'), absoluteURL.path)
    FileUtils.rm_rf(tmp)
    true
  rescue Exception => exception
    info = { NSLocalizedFailureReasonErrorKey => exception.message }
    outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:info))
    false
  end

  def makeWindowControllers
    @controller = BookWindowController.alloc.init
    addWindowController(@controller)
  end
  
  def relativePathFor(filepath)
    filepath.gsub(@unzippath, '')
  end
  
  private

  def opfXML
    book = self
    ERB.new(Bundle.template("content.opf")).result(binding)
  end

  def runCommand(command)
    result = `#{command}  2>&1`
    raise result unless $?.success? 
    result
  end

end
