class Package

  def initialize(book)
    raise "the OPF file #{book.container.absolutepath} is missing" unless File.exists?(book.container.absolutepath)
    doc = REXML::Document.new(File.read(book.container.absolutepath))
    parseMetadata(book, doc)
    parseManifest(book, doc)
    parseSpine(book, doc)
  end
  
  def save(book, src, dest)
    File.open("#{dest}/OEBPS/content.opf", "w") do |f|
      f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      f.puts "<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookID\" version=\"2.0\">"
      f.puts "  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:opf=\"http://www.idpf.org/2007/opf\">"
      f.puts "    <dc:title>#{book.title}</dc:title>"
      f.puts "    <dc:creator opf:role=\"aut\">#{book.creator}</dc:creator>"
      f.puts "    <dc:description>#{book.description}</dc:description>"
      f.puts "    <dc:publisher>#{book.publisher}</dc:publisher>"
      f.puts "    <dc:language>#{book.language}</dc:language>"
      f.puts "    <dc:identifier id=\"BookID\" opf:scheme=\"UUID\">#{book.identifier}</dc:identifier>"
      f.puts "  </metadata>"
      f.puts "  <manifest>"
      f.puts "    <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\"/>"
      book.entries.each do |entry|
        if entry.id && entry.manifestable?
          f.puts "    <item id=\"#{entry.id}\" href=\"#{entry.href}\" media-type=\"#{entry.mediaType}\"/>"
          FileUtils.mkdir_p(File.dirname("#{dest}/#{entry.href}"))
          puts "#{src}/#{book.container.root}/#{entry.href}"
          FileUtils.cp("#{src}/#{book.container.root}/#{entry.href}", "#{dest}/OEBPS/#{entry.href}")
        end
      end
      f.puts "  </manifest>"
      f.puts "  <spine toc=\"ncx\">"
      book.spine.each do |entry|
        f.puts "    <itemref idref=\"#{entry.id}\"/>"
      end
      f.puts "  </spine>"
      f.puts "</package>"
    end
  end
  
  private
  
  def parseMetadata(book, doc)
    doc.elements.each("/package/metadata/*") do |element|
      case element.name
      when 'title'
        book.title = element.text
      when 'publisher'
        book.publisher = element.text
      when 'creator'
        book.creator = element.text
      when 'date'
        book.date = element.text
      when 'language'
        book.language = element.text
      when 'description'
        book.description = element.text
      when 'rights'
        book.rights = element.text
      when 'identifier'
        book.identifier = element.text
      when 'subject'
        book.subject = element.text
      else
        #puts "unparsed metadata element: #{element}" if element.name.strip.size != 0
      end
    end
    p book
  end
  
  def parseManifest(book, doc)
    puts "parseManifest"
    doc.elements.each("/package/manifest/item") do |element|
      entry = book.entryWithHref(element.attributes["href"])
      raise "an OPF manifest item element has an invalid href value: #{element.attributes["href"]}" unless entry
      entry.id = element.attributes["id"]
      entry.mediaType = element.attributes["media-type"]
    end
  end

  def parseSpine(book, doc)
    puts "parseSpine"
    book.ncx = book.entryWithId(doc.elements["/package/spine"].attributes["toc"])
    raise "an NCX file is not speicifed in the spine as required." unless book.ncx
    
    previous = nil
    doc.elements.each("/package/spine/itemref") do |element|
      entry = book.entryWithId(element.attributes["idref"])
      raise "a OPF spine itemref element has an invalid idref value: #{element.attributes["idref"]}" unless entry
      book.spine << entry
      entry.previous = previous
      previous.next = entry if previous
      previous = entry
    end
  end

#  def parseGuide(book, doc)
#    puts "parseGuide"
#    doc.elements.each("/package/guide/reference") do |element|
#      entry.referenceTitle = element.attributes["title"]
#      entry.referenceType = element.attributes["type"]
#    end
#  end

end