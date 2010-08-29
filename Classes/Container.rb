class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :root

  def initialize(book)
    file = "#{book.base}/#{CONTAINER_XML_PATH}"
    raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(file)
    path = REXML::Document.new(File.read(file)).root.elements["rootfiles/rootfile"].attributes["full-path"]
    raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless path
    @opfPath = "#{book.base}/#{path}"
    @root = File.dirname(@opfPath)
  end
  
  def save(directory)
    FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{directory}/#{CONTAINER_XML_PATH}")
  end
  
  def opfDoc
    raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
    @opfDoc ||= REXML::Document.new(File.read(@opfPath))
  end

end