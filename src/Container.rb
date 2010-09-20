class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :root, :base, :opfPath

  def initialize(book)
    xmlPath = "#{book.base}/#{CONTAINER_XML_PATH}"
    raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(xmlPath)
    @opfPath = REXML::Document.new(File.read(xmlPath)).root.elements["rootfiles/rootfile"].attributes["full-path"]
    raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless @opfPath
    @base = File.dirname(@opfPath)
    @opfFullPath = "#{book.base}/#{@opfPath}"
    @root = File.dirname(@opfFullPath)
  end

  def opfDoc
    raise "The OPF file is missing: #{File.basename(@opfFullPath)}" unless File.exists?(@opfFullPath)
    @opfDoc ||= REXML::Document.new(File.read(@opfFullPath))
  end

  def save(directory)
    FileUtils.mkdir_p("#{directory}/#{@base}")
    FileUtils.mkdir_p("#{directory}/META-INF")
    File.open("#{directory}/META-INF/container.xml", 'w') {|f| f.write(to_xml)}
  end

  def to_xml
    @container = self
    ERB.new(File.read(NSBundle.mainBundle.pathForResource("container.xml", ofType:"erb"))).result(binding)
  end

end