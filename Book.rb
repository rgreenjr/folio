require "rexml/document"
require "fileutils"
require "erb"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html
#
# Some terms have optional attributes:
# 
# creator, contributor
#   opf:role — see http://www.loc.gov/marc/relators/ for values
# date
#   opf:event — unstandardised: use something sensible
# identifier
#   opf:scheme — unstandardised: use something sensible
# date, format, identifier, language, type
#   xsi:type — use an appropriate standard term (such as W3CDTF for date)
# contributor, coverage, creator, description, publisher, relation, rights, source, subject, title
#   xml:lang — use RFC-3066 format

class Book

  # required attributes
  attr_accessor :title, :language, :identifier
    
  # optional attributes
  attr_accessor :creator, :contributor, :publisher, :subject, :description, :date, :type, :format, :source, :relation, :coverage, :rights
  
  attr_accessor :spine, :navMap

  def initialize(filepath)
    @spine = []
    @filepath = filepath
    @root = "/Users/rgreen/Desktop/extract"
    FileUtils.rm_rf(@root)
    Dir.mkdir(@root)
    system("unzip -q -d '#{@root}' \"#{@filepath}\"")
    parse_opf
    @navMap = NavMap.new(ncx)
    # puts @navMap.to_xml
  end
  
  def entries
    unless @entries
      @entries = Dir["#{@root}/**/*"]
      @entries.reject! {|entry| File.directory?(entry)}
      @entries.collect! {|entry| Entry.new(@root, entry.sub(@root + '/', ''))}
    end
    @entries
  end

  def save(filepath)
    @tmp = "/Users/rgreen/Desktop/tmp"
    FileUtils.rm_rf(@tmp)
    FileUtils.mkdir_p(["#{@tmp}/META-INF", "#{@tmp}/OEBPS"])
    FileUtils.cp(NSBundle.mainBundle.pathForResource("mimetype", ofType:nil), "#{@tmp}/mimetype")
    FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{@tmp}/META-INF/container.xml")
    save_ncx("#{@tmp}/OEBPS/toc.ncx")
    save_opf("#{@tmp}/OEBPS/content.opf")
    system("cd '#{@tmp}'; zip -X0 '/Users/rgreen/Desktop/#{@title}.epub' mimetype")
    system("cd '#{@tmp}'; zip -X9r '/Users/rgreen/Desktop/#{@title}.epub' . -x mimetype")
  end
  
  def save_opf(filepath)
    File.new(filepath, "w")
    File.open(filepath, "w") do |f|
      f.puts "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      f.puts "<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookID\" version=\"2.0\">"
      f.puts "  <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:opf=\"http://www.idpf.org/2007/opf\">"
      f.puts "    <dc:title>#{@title}</dc:title>"
      f.puts "    <dc:creator opf:role=\"aut\">#{@author}</dc:creator>"
      f.puts "    <dc:description>#{@description}</dc:description>"
      f.puts "    <dc:publisher>#{@publisher}</dc:publisher>"
      f.puts "    <dc:language>#{@language}</dc:language>"
      f.puts "    <dc:identifier id=\"BookID\" opf:scheme=\"UUID\">#{@identifier}</dc:identifier>"
      f.puts "  </metadata>"
      f.puts "  <manifest>"
      entries.each do |entry|
        if entry.id && entry.manifestable?
          f.puts "    <item id=\"#{entry.id}\" href=\"#{entry.href}\" media-type=\"#{entry.mediaType}\"/>"
          FileUtils.mkdir_p(File.dirname("#{@tmp}/#{entry.href}"))
          FileUtils.cp("#{@root}/#{entry.href}", "#{@tmp}/#{entry.href}")
        end
      end
      f.puts "  </manifest>"
      f.puts "  <spine toc=\"ncx\">"
      spine.each do |entry|
        f.puts "    <itemref idref=\"#{entry.id}\"/>"
      end
      f.puts "  </spine>"
      f.puts "</package>"
    end
  end
  
  def save_ncx(filepath)
    File.new(filepath, "w")
    File.open(filepath, "w") do |f|
      f.puts @navMap.to_xml
    end
  end

  def entryAt(index)
    @entries[index]
  end
  
  def indexForEntry(entry)
    @entries.each_with_index do |e, index|
      return index if e == entry
    end
    nil
  end
  
  def entryWithHref(href)
    entry = entries.select {|entry| entry.href == href}.first
    entry = entries.select {|entry| entry.href == "#{opf.dirname}/#{href}"}.first unless entry
    entry
  end

  def entryWithId(id)
    entries.select {|entry| entry.id == id}.first
  end
  
  def spineEntryBefore(entry)
    index = spineIndexForEntry(entry)
    if (index - 1 > -1)
      return @spine[index - 1]
    else
      entry
    end
  end

  def spineEntryAfter(entry)
    index = spineIndexForEntry(entry)
    if (index + 1 < @spine.size)
      return @spine[index + 1]
    else
      entry
    end
  end
  
  private

  def parse_opf
    doc = REXML::Document.new(opf.content)
    parseMetadata(doc)
    parseManifest(doc)
    parseSpine(doc)
    #parseGuide(doc)
  end

  def parseMetadata(doc)
    doc.elements.each("/package/metadata/*") do |element|
      case element.name
      when 'title'
        @title = element.text
      when 'publisher'
        @publisher = element.text
      when 'creator'
        @creator = element.text
      when 'date'
        @date = element.text
      when 'language'
        @language = element.text
      when 'description'
        @description = element.text
      when 'rights'
        @rights = element.text
      when 'identifier'
        @identifier = element.text
      when 'subject'
        @subject = element.text
      else
        #puts "unparsed metadata element: #{element}" if element.name.strip.size != 0
      end
    end
  end

  def parseManifest(doc)
    puts "parseManifest"
    doc.elements.each("/package/manifest/item") do |element|
      entry = entryWithHref(element.attributes["href"])
      raiseParseException("a OPF manifest item element has an invalid href value: #{element.attributes["href"]}") unless entry
      entry.id = element.attributes["id"]
      entry.mediaType = element.attributes["media-type"]
    end
  end

  def parseSpine(doc)
    puts "parseSpine"
    previous = nil
    doc.elements.each("/package/spine/itemref") do |element|
      entry = entryWithId(element.attributes["idref"])
      raiseParseException("a OPF spine itemref element has an invalid idref value: #{element.attributes["idref"]}") unless entry
      @spine << entry
      entry.previous = previous
      previous.next = entry if previous
      previous = entry
    end
  end

  def parseGuide(doc)
    puts "parseGuide"
    doc.elements.each("/package/guide/reference") do |element|
      entry.referenceTitle = element.attributes["title"]
      entry.referenceType = element.attributes["type"]
    end
  end

  def opf
    unless @opf
      href = REXML::Document.new(container.content).root.elements["rootfiles/rootfile"].attributes["full-path"]
      @opf = entryWithHref(href)
      raiseParseException("the OPF file #{href} is missing") unless @opf
    end
    @opf
  end

  def container
    unless @container
      @container = entryWithHref("META-INF\/container.xml")
      raiseParseException("the META-INF/container.xml file is missing") unless @container
    end
    @container
  end

  def ncx
    unless @ncx
      @ncx = entryMatching(".*\.ncx$")
      raiseParseException("the NCX file is missing") unless @ncx
    end
    @ncx
  end
  
  def entryMatching(regex)
    entries.each do |entry|
      return entry if entry.name =~ /#{regex}/
    end
    nil
  end
  
  def spineIndexForEntry(entry)
    @spine.each_with_index do |e, index|
      return index if e == entry
    end
    -1
  end

  def raiseParseException(reason)
    raise "Book #{@filepath} cannot be opened because #{reason}."
  end

end
