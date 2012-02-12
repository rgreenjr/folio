class XMLLint

  def self.validate(content, mediaType, issues=[])
    doc = parseXML(content)
    if doc && doc.DTD
      arguments = "--noout --nonet --valid"
    else
      path = schemaPathForMediaType(mediaType)
      arguments = path ? "--noout --schema #{path}" : "--noout"
    end

    tempfileWithContent(content) do |input|
      errors = `#{command} #{arguments} #{input.path} 2>&1`
      errors.split(/\n/).each do |line|
        if line =~ /#{input.path}:(\d+):(.*)/
          lineNumber = $1
          message = scrubMessage($2)
          issues << Issue.new(message, lineNumber)
        else
          # puts "*** #{line}"
        end
      end
    end

    issues
  end

  def self.format(content, mediaType)
    formattedText = nil
    issues = []
    errors = Tempfile.open('me.folioapp.xmllint.errors.')
    output = Tempfile.open('me.folioapp.xmllint.output.')
    begin
      doc = parseXML(content)
      arguments = (doc && doc.DTD) ? "--format --nonet --valid" : "--format"
      tempfileWithContent(content) do |input|        
        system("#{command} #{arguments} #{input.path} 1>#{output.path} 2>#{errors.path}")
        if errors.size == 0
          formattedText = File.read(output)
        else
          errors.each_line do |line|
            if line =~ /^#{input.path}:([0-9]+): (.*)/
              lineNumber = $1.to_i
              message = $2.gsub("parser error : ", "")
              issues << Issue.new(message, lineNumber)
            end
          end
        end
      end      
    ensure
      errors.close
      errors.unlink
      output.close
      output.unlink
    end
    [formattedText, issues]
  end

  private

  def self.schemaPathForMediaType(mediaType)
    mediaType == Media::HTML ? File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/xhtml1-strict.xsd") : nil
  end

  def self.scrubMessage(message)
    message = message.gsub(/\{http:\/\/www.w3.org\/(1999|2000)\/(xhtml|svg)\}/, '')
    message = message.gsub(/^ element \w*: /, '')
    message = message.gsub('Schemas validity error : ', '')
    message = message.gsub(/^ parser error : /, '')
    message = message.gsub(/: This element is not expected. Expected is one of /, ' is not allowed in this context and should be one of ')
  end

  def self.tempfileWithContent(content)
    tmp = Tempfile.new('me.folioapp.xmllint.valid')
    begin
      File.open(tmp, "w") { |f| f.print content }
      yield(tmp)
    ensure
      tmp.close
      tmp.unlink
    end
  end

  def self.command
    @catalogPath ||= File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/catalog.xml")
    "XML_CATALOG_FILES=#{@catalogPath} xmllint"
  end

  def self.parseXML(content)
    error = Pointer.new(:id)
    NSXMLDocument.alloc.initWithXMLString(content, options:0, error:error)
  end

end