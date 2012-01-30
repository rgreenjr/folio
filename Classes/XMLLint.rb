class XMLLint

  def self.validate(content, mediaType, issues=[])    
    dtdPath = Media.dtdPathForType(mediaType)
    arguments = dtdPath.nil? ? "--noout" : "--noout --dtdvalid #{dtdPath}"
    execute(arguments, content) do |success, path, output|
      output.split(/\n/).each do |line|
        if line =~ /#{path}:(\d+):(.*)/
          issues << Issue.new($2, $1)
          # puts issues.last
        else
          puts "***       #{line}"
        end
      end
    end
    issues
  end
  
  def self.findFragments(content)
    error = Pointer.new(:id)
    doc = NSXMLDocument.alloc.initWithXMLString(content, options:0, error:error)
    
    showDTD(doc)
    
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
  
  def self.showDTD(xmlDocument)
    return nil unless xmlDocument && xmlDocument.DTD
    puts "xmlDocument.DTD.publicID = #{xmlDocument.DTD.publicID}"
    puts "xmlDocument.DTD.systemID = #{xmlDocument.DTD.systemID}"
  end
  
  private
  
  def self.execute(arguments, content, &block)
    tmp = Tempfile.new('com.folioapp.tmp.')
    File.open(tmp, "w") { |f| f.print content }
    output = `xmllint #{arguments} #{tmp.path} 2>&1`
    yield($?.success?, tmp.path, output)
    tmp.delete
  end
  
end
