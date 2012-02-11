class Container

  META_INF_DIRECTORY   = "META-INF"
  CONTAINER_XML_NAME   = "container.xml"
  CONTAINER_XML_PATH   = File.join(META_INF_DIRECTORY, CONTAINER_XML_NAME)
  ENCRYPTION_XML_PATH  = File.join(META_INF_DIRECTORY, "encryption.xml")

  attr_reader   :absolutePath
  attr_accessor :package

  def self.load(unzipPath)
    raise "This book is encrytped and cannot be opened." if File.exists?(File.join(unzipPath, ENCRYPTION_XML_PATH))
    container = Container.new(unzipPath)
    raise "The \"#{CONTAINER_XML_PATH}\" file is missing." unless File.exists?(container.absolutePath)
    doc = REXML::Document.new(File.read(container.absolutePath))
    container.package = Package.load(unzipPath, extractRootFilePath(doc))
    container
  rescue REXML::ParseException => exception
    raise StandardError, "Unable to parse \"#{CONTAINER_XML_PATH}\": #{exception.explain}"
  end

  def initialize(unzipPath)
    @unzipPath = unzipPath
    @absolutePath = File.join(@unzipPath, CONTAINER_XML_PATH)
  end

  def save(directory)
    # FileUtils.mkdir_p(File.join(directory, @relativePath))    
    FileUtils.mkdir_p(File.join(directory, META_INF_DIRECTORY))
    File.open(File.join(directory, CONTAINER_XML_PATH), "w") { |f| f.write(to_xml) }
  end

  def to_xml
    ERB.new(Bundle.template(CONTAINER_XML_NAME)).result(binding)
  end

  def mediaType
    Media::EPUB
  end

  private

  def self.extractRootFilePath(doc)
    doc.root.elements.each("/container/rootfiles/rootfile") do |element|
      if element.attributes["media-type"] == Media::EPUB
        fullPath = element.attributes["full-path"]
        return fullPath unless fullPath.blank?
      end
    end
    raise "The #{CONTAINER_XML_PATH} does not specify an #{Media::EPUB} rendition."
  end

end
