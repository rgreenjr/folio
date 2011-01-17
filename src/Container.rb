class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :relativePath, :absolutePath, :opfDoc, :opfPath

  def initialize(unzipPath, book=nil)
    if book.nil?
      @relativePath = 'OEBPS'
      @absolutePath = @relativePath == '' ? unzipPath : File.join(unzipPath, @relativePath)
      FileUtils.mkdir_p(@absolutePath) unless File.exist?(@absolutePath)
      @opfPath = ''
      @opfDoc = nil
    else
      begin
        xmlPath = File.join(unzipPath, CONTAINER_XML_PATH)
        raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(xmlPath)

        doc = REXML::Document.new(File.read(xmlPath))

        @opfPath = doc.root.elements["rootfiles/rootfile"].attributes["full-path"]
        raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless @opfPath

        @relativePath = File.dirname(@opfPath).split('/').last
        @relativePath = '' if @relativePath == '.'
        @absolutePath = @relativePath == '' ? unzipPath : File.join(unzipPath, @relativePath)

        @opfPath = File.join(unzipPath, @opfPath)

        raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
        @opfDoc = REXML::Document.new(File.read(@opfPath))

      rescue REXML::ParseException => exception
        raise StandardError, "An error occurred while parsing #{CONTAINER_XML_PATH}: #{exception.explain}"
      end
    end
  end
  
  def save(directory)
    FileUtils.mkdir_p("#{directory}/#{@relativePath}")
    FileUtils.mkdir_p("#{directory}/META-INF")
    File.open("#{directory}#{CONTAINER_XML_PATH}", "w") {|f| f.write(to_xml)}
  end

  def to_xml
    opfPath = @relativePath.empty? ? "content.opf" : "#{@relativePath}/content.opf"
    ERB.new(Bundle.template("container.xml")).result(binding)
  end

end
