# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

# Required files:
#
# mimetype
# META-INF/container.xml
#
# OEBPS/toc.ncx (variable path and filename)
# OEBPS/content.opf (variable path and filename)

class Book < NSDocument

  attr_reader :controller, :unzipPath
  attr_reader :navigation, :manifest, :spine, :container, :metadata, :guide
  
  def initWithType(typeName, error:outError)
    super
    @unzipPath  = Dir.mktmpdir("folio-unzip-")
    @container  = Container.new(@unzipPath)
    @manifest   = Manifest.new(@container.absolutePath)
    @metadata   = Metadata.new
    @spine      = Spine.new
    @guide      = Guide.new
    @navigation = Navigation.new
    self
  end
  
  def readFromURL(absoluteURL, ofType:inTypeName, error:outError)
    @unzipPath  = Dir.mktmpdir("folio-unzip-")
    runCommand("unzip -q -d '#{@unzipPath}' \"#{absoluteURL.path}\"")
    @container  = Container.new(@unzipPath, self)
    @manifest   = Manifest.new(@container.absolutePath, self)
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
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.relativePath)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.relativePath, "content.opf"), "w") {|f| f.puts opfXML}
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
    puts "relativePathFor #{filepath}"
    filepath = filepath.gsub(@unzipPath + '/', '')
    filepath = filepath.stringByStandardizingPath
    puts "         #{filepath}"
    filepath
  end
  
  def close
    super
    FileUtils.rm_rf(@unzipPath)
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
