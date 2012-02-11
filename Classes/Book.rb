class Book < NSDocument

  UNZIP_DIRECTORY_PREFIX = "me.folioapp."
  EMPTY_BOOK_FILE_SIZE   = 1300

  attr_reader :controller
  attr_reader :unzipPath
  attr_reader :container
  attr_reader :issues
  attr_reader :fileSize

  # creates a new book
  def initWithType(typeName, error:outError)
    super
    @unzipPath = Dir.mktmpdir(UNZIP_DIRECTORY_PREFIX)
    @container = Container.new(@unzipPath)
    @issues = []
    self
  end

  # opens an existing book
  def readFromURL(absoluteURL, ofType:inTypeName, error:outError)
    progressController = ProgressController.alloc.init
    progressController.showWindowWithTitle("Opening...") do |progressBar|
      @unzipPath = Dir.mktmpdir(UNZIP_DIRECTORY_PREFIX)
      progressBar.doubleValue = 10.0
      runCommand("unzip -q -d '#{@unzipPath}' \"#{absoluteURL.path}\"")
      progressBar.doubleValue = 50.0
      @container  = Container.load(@unzipPath)
      progressBar.doubleValue = 100.0
      @issues = []
      true
    end
  # rescue Exception => exception
  #   info = { NSLocalizedRecoverySuggestionErrorKey => exception.message }
  #   outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:1 userInfo:info))
  #   false
  end

  def writeToURL(absoluteURL, ofType:inTypeName, error:outError)
    tempName = "book.epub"
    @controller.tabbedViewController.saveAllTabs(self)
    tempDirectory = Dir.mktmpdir("me.folioapp.zip.")
    File.open(File.join(tempDirectory, "mimetype"), "w") { |f| f.print "application/epub+zip" }
    @container.save(tempDirectory)
    runCommand("cd '#{tempDirectory}'; zip -qX0 ./#{tempName} mimetype")
    runCommand("cd '#{tempDirectory}'; zip -qX9urD ./#{tempName} *")
    FileUtils.mv(File.join(tempDirectory, tempName), absoluteURL.path)
    FileUtils.rm_rf(tempDirectory)
    true
  # rescue Exception => exception
  #   info = { NSLocalizedRecoverySuggestionErrorKey => exception.message }
  #   outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:1, userInfo:info))
  #   false
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
    @container.package.manifest.each { |item| item.clearIssues }
  end

  def hasIssues?
    !@issues.empty?
  end

  def totalIssueCount
    @issues.size + @container.package.manifest.totalIssueCount
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

  def validatePackage
    if isDocumentEdited
      XMLLint.validate(@container.package.opfXML, @issues)
    elsif @container.package.opf
      XMLLint.validate(@container.package.opf.to_s, @issues)
    end
  end

  def validateContainer
    XMLLint.validate(@container.containerXML, @issues)
  end

  def validateMetadata
    @container.package.metadata.validate(@issues)
  end

  def validateManifest
    undeclaredItems.each do |filename| 
      addIssue(Issue.new("The item \"#{filename}\" is present but not declared in the manifest."))
    end
  end

  def validateNavigation
    @container.package.navigation.validate(@issues)
  end

  def undeclaredItems
    undeclared = []
    ignore = [File.join(@unzipPath, "mimetype"), @container.absolutePath, @container.package.absoluteFullPath, @container.package.manifest.ncx.path]
    Dir.glob("#{@unzipPath}/**/*").each do |entry|
      unless ignore.include?(entry) || File.directory?(entry) || @container.package.manifest.itemWithHref(entry)
        undeclared << relativePathFor(entry)
      end
    end
    undeclared
  end

  private

  def runCommand(command)
    result = `#{command}  2>&1`
    raise result unless $?.success? 
  end

end
