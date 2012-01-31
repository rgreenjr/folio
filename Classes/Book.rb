# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

# Required files:
#
# mimetype
# META-INF/container.xml
#
# OEBPS/toc.ncx (variable path and filename)
# OEBPS/content.opf (variable path and filename)

class Book < NSDocument
  
  UNZIP_DIRECTORY_PREFIX = "com.folioapp."
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
    @manifest   = Manifest.new(@container)
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
        @container  = Container.new(@unzipPath, self)
        progressBar.doubleValue = 50.0
        @manifest   = Manifest.new(@container)
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
      rescue Exception => exception
        info = {
          NSLocalizedFailureReasonErrorKey => "\n\n" + exception.message
        }
        outError.assign(NSError.errorWithDomain(NSOSStatusErrorDomain, code:-4, userInfo:info))
        false
      end
    end
  end

  def writeToURL(absoluteURL, ofType:inTypeName, error:outError)
    @controller.tabbedViewController.saveAllTabs(self)
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
    @issues.size + @manifest.totalIssueCount# + @navigation.totalIssueCount
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
    # if isDocumentEdited
    #   @container
    # else
      # XMLLint.validate(opfXML, @issues)
    # end
  end
  
  # def validateContainer
  #   XMLLint.validate(@container.to_xml, @issues)
  # end
  
  def validateMetadata
    @issues.concat(@metadata.issues) unless @metadata.valid?
  end
  
  def validateManifest
    @manifest.valid?
    undeclaredItems.each do |filename| 
      addIssue(Issue.new("The file \"#{filename}\" is present but not declared in the manifest."))
    end
  end
  
  def validateNavigation
    # @issues.concat(@navigation.issues) 
    # unless @navigation.valid?
    #   @navigation.pointsWithIssues.each { |point| point. }
    # end
  end
  
  def undeclaredItems
    undeclared = []
    ignore = ["META-INF/container.xml", "mimetype"].map { |item| "#{@unzipPath}/#{item}" }
    ignore << @container.opfAbsolutePath
    ignore << @manifest.ncx.path
    Dir.glob("#{@unzipPath}/**/*").each do |entry|
      unless ignore.include?(entry) || File.directory?(entry) || @manifest.itemWithHref(entry)
        undeclared << relativePathFor(entry)
      end
    end
    undeclared
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
