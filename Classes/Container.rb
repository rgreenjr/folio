class Container

  EPUB_MEDIA_TYPE              = "application/oebps-package+xml"
  META_INF_DIRECTORY           = "META-INF"
  CONTAINER_XML_NAME           = "container.xml"
  CONTAINER_XML_RELATIVE_PATH  = File.join(META_INF_DIRECTORY, CONTAINER_XML_NAME)

  DEFAULT_CONTENT_OPF_NAME     = "content.opf"
  DEFAULT_RELATIVE_PATH        = "OEBPS"
  
  attr_reader :relativePath, :absolutePath, :opfDoc, :opfAbsolutePath, :opfRelativePath

  def initialize(unzipPath, book=nil)
    if book.nil?
      @relativePath = DEFAULT_RELATIVE_PATH
      @absolutePath = makeAbsolutePath(unzipPath)
      FileUtils.mkdir_p(@absolutePath) unless File.exist?(@absolutePath)
      @opfAbsolutePath = ''
      @opfDoc = nil
    else
      begin
        xmlPath = File.join(unzipPath, CONTAINER_XML_RELATIVE_PATH)
        raise "The #{CONTAINER_XML_RELATIVE_PATH} file is missing." unless File.exists?(xmlPath)

        doc = REXML::Document.new(File.read(xmlPath))

        @opfRelativePath = extractRootFilePath(doc)

        @relativePath = File.dirname(@opfRelativePath).split('/').last
        @relativePath = '' if @relativePath == '.'
        @absolutePath = makeAbsolutePath(unzipPath)

        @opfAbsolutePath = File.join(unzipPath, @opfRelativePath)

        raise "The #{File.basename(@opfAbsolutePath)} could not found." unless File.exists?(@opfAbsolutePath)
        
        @opfDoc = REXML::Document.new(File.read(@opfAbsolutePath))

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
    fullPath = @relativePath.empty? ? DEFAULT_CONTENT_OPF_NAME : File.join(@relativePath, DEFAULT_CONTENT_OPF_NAME)
    ERB.new(Bundle.template(CONTAINER_XML_NAME)).result(binding)
  end
  
  private
  
  def makeAbsolutePath(unzipPath)
    @relativePath == '' ? unzipPath : File.join(unzipPath, @relativePath)
  end
  
  def extractRootFilePath(doc)
    doc.root.elements.each("/container/rootfiles/rootfile") do |element|
      if element.attributes["media-type"] == EPUB_MEDIA_TYPE
        return element.attributes["full-path"]
      end
    end
    raise "The #{CONTAINER_XML_RELATIVE_PATH} does not specify an #{EPUB_MEDIA_TYPE} rendition."
  end

end
