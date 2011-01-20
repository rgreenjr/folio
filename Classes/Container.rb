class Container

  META_INF_DIRECTORY           = "META-INF"
  CONTAINER_XML_NAME           = "container.xml"
  CONTAINER_XML_RELATIVE_PATH  = File.join(META_INF_DIRECTORY, CONTAINER_XML_NAME)

  DEFAULT_CONTENT_OPF_NAME     = "content.opf"
  DEFAULT_RELATIVE_PATH        = "OEBPS"
  
  attr_reader :relativePath, :absolutePath, :opfDoc, :opfPath

  def initialize(unzipPath, book=nil)
    if book.nil?
      @relativePath = DEFAULT_RELATIVE_PATH
      @absolutePath = makeAbsolutePath(unzipPath)
      FileUtils.mkdir_p(@absolutePath) unless File.exist?(@absolutePath)
      @opfPath = ''
      @opfDoc = nil
    else
      begin
        xmlPath = File.join(unzipPath, CONTAINER_XML_RELATIVE_PATH)
        raise "The #{CONTAINER_XML_RELATIVE_PATH} file is missing." unless File.exists?(xmlPath)

        doc = REXML::Document.new(File.read(xmlPath))

        @opfPath = doc.root.elements["rootfiles/rootfile"].attributes["full-path"]
        raise "The #{CONTAINER_XML_RELATIVE_PATH} does not specify an OPF file." unless @opfPath

        @relativePath = File.dirname(@opfPath).split('/').last
        @relativePath = '' if @relativePath == '.'
        @absolutePath = makeAbsolutePath(unzipPath)

        @opfPath = File.join(unzipPath, @opfPath)

        raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
        @opfDoc = REXML::Document.new(File.read(@opfPath))

      rescue REXML::ParseException => exception
        raise StandardError, "An error occurred while parsing #{CONTAINER_XML_RELATIVE_PATH}: #{exception.explain}"
      end
    end
  end
  
  def save(directory)
    FileUtils.mkdir_p(File.join(directory, @relativePath))    
    FileUtils.mkdir_p(File.join(directory, META_INF_DIRECTORY))
    File.open(File.join(directory, CONTAINER_XML_RELATIVE_PATH), "w") {|f| f.write(to_xml)}
  end

  def to_xml
    opfPath = @relativePath.empty? ? DEFAULT_CONTENT_OPF_NAME : File.join(@relativePath, DEFAULT_CONTENT_OPF_NAME)
    ERB.new(Bundle.template(CONTAINER_XML_NAME)).result(binding)
  end
  
  private
  
  def makeAbsolutePath(unzipPath)
    @relativePath == '' ? unzipPath : File.join(unzipPath, @relativePath)
  end

end