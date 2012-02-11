class Package

  DEFAULT_DIRECTORY = "OEBPS"
  DEFAULT_FILENAME  = "content.opf"
  DEFAULT_FULL_PATH = File.join(DEFAULT_DIRECTORY, DEFAULT_FILENAME)

  attr_reader   :fullPath
  attr_reader   :absoluteFullPath
  attr_reader   :absoluteDirectory
  attr_reader   :directory
  attr_accessor :opf

  # attr_reader :metadata
  # attr_reader :manifest
  # attr_reader :spine
  # attr_reader :guide

  def self.load(unzipPath, fullPath)
    package = Package.new(unzipPath, fullPath)
    raise "The OPF file \"#{fullPath}\" could not be found." unless File.exists?(package.absoluteFullPath)
    package.opf = REXML::Document.new(File.read(package.absoluteFullPath))
    package
  rescue REXML::ParseException => exception
    raise StandardError, "Unable to parse OPF file \"#{fullPath}\": #{exception.explain}"
  end

  def initialize(unzipPath, fullPath=nil)
    @unzipPath = unzipPath
    @fullPath = fullPath || DEFAULT_FULL_PATH
    @absoluteFullPath = File.join(@unzipPath, @fullPath)
    @directory = File.dirname(@fullPath)
    @absoluteDirectory = File.dirname(@absoluteFullPath)
    FileUtils.mkdir_p(@absoluteDirectory)
  end

  def each(path)
    return unless @opf
    @opf.elements.each("package/#{path}") { |element| yield element }
  end

  def makePathRelative(path)
    path.gsub(@absoluteDirectory + "/", '')
  end

end
