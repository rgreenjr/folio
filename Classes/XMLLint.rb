class XMLLint

  def self.validate(content, mediaType, issues=[])
    error = Pointer.new(:id)
    doc = NSXMLDocument.alloc.initWithXMLString(content, options:0, error:error)

    if doc && doc.DTD
      arguments = "--noout --nonet --valid"
    else
      path = schemaPathForMediaType(mediaType)
      arguments = path ? "--noout --schema #{path}" : "--noout"
    end

    execute(arguments, content) do |success, path, output|
      output.split(/\n/).each do |line|
        if line =~ /#{path}:(\d+):(.*)/
          issues << Issue.new($2, $1)
        else
          puts "*** #{line}"
        end
      end
    end

    issues
  end

  def self.findFragments(content)
    error = Pointer.new(:id)
    doc = NSXMLDocument.alloc.initWithXMLString(content, options:0, error:error)
    raise error[0].localizedDescription if error[0]
    array = doc.nodesForXPath("//*[@id]", error:error)
    raise error[0].localizedDescription if error[0]
    fragments = []
    array.each do |element|
      element.attributes.each do |attribute|
        fragments << attribute.stringValue if attribute.name == 'id'
      end
    end
    fragments
  end

  private

  def self.execute(arguments, content, &block)
    tmp = Tempfile.new('com.folioapp.tmp.')
    File.open(tmp, "w") { |f| f.print content }
    # puts "cd #{resourcesPath}; XML_CATALOG_FILES=#{catalogPath} xmllint #{arguments} #{tmp.path} 2>&1"
    output = `cd #{resourcesPath}; XML_CATALOG_FILES=#{catalogPath} xmllint #{arguments} #{tmp.path} 2>&1`
    yield($?.success?, tmp.path, output)
    tmp.delete
  end

  def self.catalogPath
    @catalogPath ||= File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/catalog.xml")
  end

  def self.resourcesPath
    @workingPath ||= File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources")
  end

  def self.schemaPathForMediaType(mediaType)
    case mediaType
    when Media::HTML
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/xhtml1-strict.xsd")
    else
      nil
    end
  end

  def self.dtdPathForMediaType(mediaType)
    case mediaType
    when Media::HTML
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/xhtml1-strict.dtd")
    when Media::NCX
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/ncx-2005-1.dtd")
    when Media::OPF
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/opf20.dtd")
    else
      nil
    end
  end
  
end
