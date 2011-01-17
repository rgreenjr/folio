class Container

  CONTAINER_XML_PATH = "/META-INF/container.xml"

  attr_reader :path, :opfDoc, :opfPath

  def initialize(unzipPath, book=nil)
    if book.nil?
      @path = ''
      @opfPath = ''
      @opfDoc = nil
    else
      begin
        xmlPath = File.join(unzipPath, CONTAINER_XML_PATH)
        raise "The #{CONTAINER_XML_PATH} file is missing." unless File.exists?(xmlPath)

        doc = REXML::Document.new(File.read(xmlPath))

        @opfPath = doc.root.elements["rootfiles/rootfile"].attributes["full-path"]
        raise "The #{CONTAINER_XML_PATH} does not specify an OPF file." unless @opfPath

        @path = File.dirname(@opfPath).split('/').last
        @path = '' if @path == '.'

        @opfPath = File.join(unzipPath, @opfPath)

        raise "The OPF file is missing: #{File.basename(@opfPath)}" unless File.exists?(@opfPath)
        @opfDoc = REXML::Document.new(File.read(@opfPath))

      rescue REXML::ParseException => exception
        raise StandardError, "An error occurred while parsing #{CONTAINER_XML_PATH}: #{exception.explain}"
      end
    end
  end

  def save(directory)
    FileUtils.mkdir_p("#{directory}/#{@path}")
    FileUtils.mkdir_p("#{directory}/META-INF")
    File.open("#{directory}#{CONTAINER_XML_PATH}", "w") {|f| f.write(to_xml)}
  end

  def to_xml
    opfPath = @path.empty? ? "content.opf" : "#{@path}/content.opf"
    ERB.new(Bundle.template("container.xml")).result(binding)
  end

end
