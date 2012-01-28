class XMLLint

  @@entities = {
    "http://www.idpf.org/dtds/2007/opf.dtd"                   => "opf20.dtd",
    "http://openebook.org/dtds/oeb-1.2/oeb12.ent"             => "oeb12.dtdinc",
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd" => "xhtml1-transitional.dtd",
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"       => "xhtml1-strict.dtd",
    "http://www.w3.org/TR/xhtml1/DTD/xhtml-lat1.ent"          => "xhtml-lat1.dtdinc",
    "http://www.w3.org/TR/xhtml1/DTD/xhtml-symbol.ent"        => "xhtml-symbol.dtdinc",
    "http://www.w3.org/TR/xhtml1/DTD/xhtml-special.ent"       => "xhtml-special.dtdinc",
    "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"        => "svg11.dtd",
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"            => "opf20.dtd",
    "http://www.daisy.org/z3986/2005/dtbook-2005-2.dtd"       => "dtbook-2005-2.dtd",
    "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd"          => "dtd/ncx-2005-1.dtd"
  }

  def self.validate(text, issues=[], dtdPath=nil)
    arguments = dtdPath.nil? ? "--noout" : "--noout --dtdvalid #{dtdPath}"
    execute(arguments, text) do |success, path, output|
      output.split(/\n/).each do |line|
        if line =~ /#{path}:(\d+):(.*)/
          issues << Issue.new($2, $1)
          puts issues.last
        else
          puts "***       #{line}"
        end
      end
    end
    issues
  end
  
  def self.findFragments(text)
    error = Pointer.new(:id)
    doc = NSXMLDocument.alloc.initWithXMLString(text, options:0, error:error)
    
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
  
  def self.execute(arguments, text, &block)
    tmp = Tempfile.new('com.folioapp.tmp.')
    File.open(tmp, "w") { |f| f.print text }
    output = `xmllint #{arguments} #{tmp.path} 2>&1`
    yield($?.success?, tmp.path, output)
    tmp.delete
  end

end
