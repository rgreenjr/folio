class Package

  DEFAULT_DIRECTORY = "OEBPS"
  DEFAULT_FILENAME  = "content.opf"
  DEFAULT_FULL_PATH = File.join(DEFAULT_DIRECTORY, DEFAULT_FILENAME)

  attr_accessor :opf                # parsed OPF file
  attr_accessor :fullPath           # path to OPF file (relative to unzipPath)
  attr_accessor :absoluteFullPath   # fully qualified path to OPF file
  attr_accessor :directory          # path to package directory (relative to unzipPath)
  attr_accessor :absoluteDirectory  # fully qualified path to package directory
  attr_accessor :metadata
  attr_accessor :manifest
  attr_accessor :spine
  attr_accessor :guide
  attr_accessor :navigation

  def self.load(unzipPath, fullPath, progressBar)
    package = Package.new(unzipPath, fullPath)
    raise "The OPF file \"#{fullPath}\" could not be found." unless File.exists?(package.absoluteFullPath)
    package.opf = REXML::Document.new(File.read(package.absoluteFullPath))
    verifyPackageVersionSupport(package.opf)
    package.manifest = Manifest.load(package)
    progressBar.doubleValue = 75
    package.metadata = Metadata.load(package)
    progressBar.doubleValue = 80
    package.spine = Spine.load(package)
    progressBar.doubleValue = 85
    package.guide = Guide.load(package)
    progressBar.doubleValue = 90
    package.navigation = Navigation.load(package)
    progressBar.doubleValue = 95
    package
  rescue REXML::ParseException => exception
    raise "Unable to parse OPF file \"#{fullPath}\": #{exception.explain}"
  end

  def initialize(unzipPath, fullPath=nil)
    @unzipPath = unzipPath
    @fullPath = fullPath || DEFAULT_FULL_PATH
    @directory = File.dirname(@fullPath)
    @absoluteFullPath = File.join(@unzipPath, @fullPath)
    @absoluteDirectory = File.dirname(@absoluteFullPath)
    FileUtils.mkdir_p(@absoluteDirectory)
    @manifest = Manifest.new(self)
    @metadata = Metadata.new
    @spine = Spine.new
    @guide = Guide.new(self)
    @navigation = Navigation.new(self)
  end

  def each(path)
    @opf.elements.each("package/#{path}") { |element| yield element } if @opf
  end

  def makePathRelative(path)
    path.gsub(@absoluteDirectory + "/", '')
  end
  
  def save(directoryPath)
    # prepend package directory to directoryPath
    subDirectory = File.join(directoryPath, @directory)
    
    # create subDirectory
    FileUtils.mkdir_p(subDirectory)
    
    # write content.opf file
    File.open(File.join(directoryPath, @fullPath), "w") { |f| f.puts opfXML }

    # save individual manifest items
    @manifest.saveAllItems(subDirectory)
    
    # write toc.ncx file
    @navigation.save(subDirectory)
  end

  def opfXML
    ERB.new(Bundle.template("content.opf")).result(binding)
  end

  private

  def self.verifyPackageVersionSupport(opf)
    version = opf.root.attributes["version"]
    unless version =~ /^2\./
      raise "The specified format version #{version} is not supported."
    end
  end

end
