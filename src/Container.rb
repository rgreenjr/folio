class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"
  
  # /var/tmp/foo/OEBPS => path
  # OEBPS => root

  attr_reader :root, :opfDoc, :opfPath

  def initialize(unzipPath, book=nil)
    @root = ''
    @opfPath = ''
    @opfDoc = nil
    
    return unless book
    
    xmlPath = File.join(unzipPath, CONTAINER_XML_PATH)
    raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(xmlPath)
    
    doc = REXML::Document.new(File.read(xmlPath))
    
    @opfPath = doc.root.elements["rootfiles/rootfile"].attributes["full-path"]
    raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless @opfPath

    @root = File.dirname(@opfPath).split('/').last
    @root = '' if @root == '.'
    
    @opfPath = File.join(unzipPath, @opfPath)
    
    raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
    @opfDoc = REXML::Document.new(File.read(@opfPath))
    
  rescue REXML::ParseException => exception
    raise StandardError, "An error occurred while parsing #{CONTAINER_XML_PATH}: #{exception.explain}"
  end
  
  def save(directory)
    FileUtils.mkdir_p("#{directory}/#{@root}")
    FileUtils.mkdir_p("#{directory}/META-INF")
    File.open("#{directory}/META-INF/container.xml", "w") {|f| f.write(to_xml)}
  end

  def to_xml
    opfPath = @root.empty? ? "content.opf" : "#{@root}/content.opf"
    ERB.new(Bundle.template("container.xml")).result(binding)
  end

end
