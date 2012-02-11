# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

# Required files:
#
# mimetype
# META-INF/container.xml
#
# OEBPS/toc.ncx (variable path and filename)
# OEBPS/content.opf (variable path and filename)
#
# EPUB version 2.0.1 consists of three specifications:
# 
# Open Publication Structure (OPS) 2.0.1, contains the formatting of its content.
# 
# Open Packaging Format (OPF) 2.0.1, describes the structure of the .epub file in XML.
# 
# Open Container Format (OCF) 2.0.1, collects all files as a ZIP archive.
# 
# EPUB internally uses XHTML or DTBook (an XML standard provided by the DAISY Consortium) to 
# represent the text and structure of the content document, and a subset of CSS to provide 
# layout and formatting. XML is used to create the document manifest, table of contents, 
# and EPUB metadata. Finally, the files are bundled in a zip file as a packaging format.

class Book < NSDocument
  
  UNZIP_DIRECTORY_PREFIX = "me.folioapp."
  EMPTY_BOOK_FILE_SIZE   = 1300

  attr_reader :controller
  attr_reader :unzipPath
  attr_reader :issues
  attr_reader :navigation
  attr_reader :manifest
  attr_reader :spine
  attr_reader :container
  attr_reader :metadata
  attr_reader :guide
  attr_reader :fileSize
  
  # creates a new book
  def initWithType(typeName, error:outError)
    super
    @unzipPath  = Dir.mktmpdir(UNZIP_DIRECTORY_PREFIX)
    @container  = Container.new(@unzipPath)
    @manifest   = Manifest.new(@container.package)
    @metadata   = Metadata.new
    @spine      = Spine.new
    @guide      = Guide.new(@container, @manifest)
    @navigation = Navigation.new
    @issues     = []
    self
  end
  
  # opens an existing book
  def readFromURL(absoluteURL, ofType:inTypeName, error:outError)
    @progressController ||= ProgressController.alloc.init
    @progressController.showWindowWithTitle("Opening...") do |progressBar|
      begin
        @unzipPath  = Dir.mktmpdir(UNZIP_DIRECTORY_PREFIX)
        progressBar.doubleValue = 10.0
        
        runCommand("unzip -q -d '#{@unzipPath}' \"#{absoluteURL.path}\"")
        progressBar.doubleValue = 40.0
        
        @container  = Container.load(@unzipPath)
        progressBar.doubleValue = 50.0
        
        p @container.package
        puts "-----"
        
        @manifest   = Manifest.new(@container.package)
        progressBar.doubleValue = 60.0
        
        @metadata   = Metadata.new(self)
        progressBar.doubleValue = 70.0
        
        @spine      = Spine.new(self)
        progressBar.doubleValue = 80.0
        
        @guide      = Guide.new(@container, @manifest)
        progressBar.doubleValue = 90.0
        
        @navigation = Navigation.new(self)
        progressBar.doubleValue = 100.0
        @issues     = []
        true
      # rescue Exception => exception
      #   info = { NSLocalizedRecoverySuggestionErrorKey => exception.message }
      #   outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:info))
      #   false
      end
    end
  end

  def writeToURL(absoluteURL, ofType:inTypeName, error:outError)
    @controller.tabbedViewController.saveAllTabs(self)
    tmp = Dir.mktmpdir("folio-zip-")
    File.open(File.join(tmp, "mimetype"), "w") {|f| f.print "application/epub+zip"}
    @container.save(tmp)
    dest = File.join(tmp, @container.package.directory)
    @manifest.save(dest)
    @navigation.save(dest)
    File.open(File.join(tmp, @container.package.fullPath), "w") {|f| f.puts opfXML}
    runCommand("cd '#{tmp}'; zip -qX0 ./folio-book.epub mimetype")
    runCommand("cd '#{tmp}'; zip -qX9urD ./folio-book.epub *")
    FileUtils.mv(File.join(tmp, 'folio-book.epub'), absoluteURL.path)
    FileUtils.rm_rf(tmp)
    true
  rescue Exception => exception
    info = { NSLocalizedRecoverySuggestionErrorKey => exception.message }
    outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:info))
    false
  end

  def makeWindowControllers
    @controller = BookWindowController.alloc.init
    addWindowController(@controller)
  end
  
  def relativePathFor(filepath)
    filepath = filepath.gsub(@unzipPath + '/', '')
    filepath.stringByStandardizingPath
  end
  
  # validation issues not specific to a manifest item are assigned to book
  def addIssue(issue)
    @issues << issue if issue
  end

  def clearIssues
    @issues.clear
    @manifest.each { |item| item.clearIssues }
  end
  
  def hasIssues?
    !@issues.empty?
  end
  
  def totalIssueCount
    @issues.size + @manifest.totalIssueCount
  end
  
  def fileSize
    if fileURL
      NSFileManager.defaultManager.attributesOfItemAtPath(fileURL.path, error:nil).fileSize
    else
      EMPTY_BOOK_FILE_SIZE
    end
  end
  
  def close
    super
    FileUtils.rm_rf(@unzipPath)
  end
  
  def validateOPF
    if isDocumentEdited
      XMLLint.validate(opfXML, @issues)
    elsif @container.package.opf
      XMLLint.validate(@container.package.opf.to_s, @issues)
    end
  end
  
  def validateContainer
    XMLLint.validate(@container.to_xml, @issues)
  end
  
  def validateMetadata
    @metadata.validate(@issues)
  end
  
  def validateManifest
    # @manifest.valid?
    undeclaredItems.each do |filename| 
      addIssue(Issue.new("The file \"#{filename}\" is present but not declared in the manifest."))
    end
  end
  
  def validateNavigation
    @navigation.validate(@issues)
  end
  
  def undeclaredItems
    undeclared = []
    ignore = [File.join(@unzipPath, "mimetype"), @container.absolutePath, @container.package.absolutePath, @manifest.ncx.path]
    Dir.glob("#{@unzipPath}/**/*").each do |entry|
      unless ignore.include?(entry) || File.directory?(entry) || @manifest.itemWithHref(entry)
        undeclared << relativePathFor(entry)
      end
    end
    undeclared
  end

  private

  # move to Package
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
