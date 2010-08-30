class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :root, :base

  def initialize(book)
    xmlPath = "#{book.base}/#{CONTAINER_XML_PATH}"
    raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(xmlPath)
    @opfPath = REXML::Document.new(File.read(xmlPath)).root.elements["rootfiles/rootfile"].attributes["full-path"]
    raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless @opfPath
    @base = File.dirname(@opfPath)
    @opfPath = "#{book.base}/#{@opfPath}"
    @root = File.dirname(@opfPath)
  end

  def opfDoc
    raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
    @opfDoc ||= REXML::Document.new(File.read(@opfPath))
  end

  def save(directory)
    FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{directory}/#{CONTAINER_XML_PATH}")
  end

end