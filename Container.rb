class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :base, :opfPath, :root

  def initialize(book)
    @base = book.base
    file = "#{@base}/#{CONTAINER_XML_PATH}"
    raise "The #{CONTAINER_XML_PATH} file is missing" unless File.exists?(file)
    path = REXML::Document.new(File.read(file)).root.elements["rootfiles/rootfile"].attributes["full-path"]
    @opfPath = "#{base}/#{path}"
    @root = File.dirname(@opfPath)
  end
  
  def save(directory)
    FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{directory}/#{CONTAINER_XML_PATH}")
  end
  
  def opfDoc
    raise "OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
    @opfDoc ||= REXML::Document.new(File.read(@opfPath))
  end

end