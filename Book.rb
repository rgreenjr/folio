require "rexml/document"
require "fileutils"
require "erb"

class Book

  attr_accessor :title, :creator, :rights, :date, :publisher, :language
  attr_accessor :subject, :description, :identifier, :spine


  def initialize(filepath)
    @spine = []
    @filepath = filepath
    @root = "/Users/rgreen/Desktop/extract"
    @rootURL = NSURL.URLWithString("file://#{@root}")
    FileUtils.rm_rf(@root)
    Dir.mkdir(@root)
    system("unzip -q -d '#{@root}' \"#{@filepath}\"")
    parse_opf
	@entries.first.tidy
  end

  def manifest
    @entries
  end

  def references
    @spine.select {|entry| entry.referenceType != nil}
  end

  def size
    @spine.size
  end

  def entry(index)
    @spine[index]
  end

  def print_opf
    @book = self
    template = File.read("/Users/rgreen/Desktop/Folio/content.opf.erb")
    erb = ERB.new(template, nil, "%<>-")
    erb.result(binding)
  end

  private

  def parse_opf
	raiseParseException("OPF file is missing") unless opf
	puts opf.dirname
    doc = REXML::Document.new(opf.content)
    parse_metadata(doc)
    parse_manifest(doc)
    parse_spine(doc)
    #parse_guide(doc)
  end

  def parse_metadata(doc)
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
        # puts "unparsed metadata element: #{element}" if element.name.strip.size != 0
      end
    end
  end

  def parse_manifest(doc)
	doc.elements.each("/package/manifest/item") do |element|
		entry = entryWithHref(element.attributes["href"])
		raiseParseException("Unable to resolve manifest item href #{element.attributes["href"]}") unless entry
		entry.id = element.attributes["id"]
		entry.mediaType = element.attributes["media-type"]
	end
  end

  def parse_spine(doc)
    doc.elements.each("/package/spine/itemref") do |element|
		entry = entryWithId(element.attributes["idref"])
		raiseParseException("Unable to resolve spine itemref idref #{element.attributes["idref"]}") unless entry
		@spine << entry
    end
  end

  def parse_guide(doc)
    doc.elements.each("/package/guide/reference") do |element|
      entry.referenceTitle = element.attributes["title"]
      entry.referenceType = element.attributes["type"]
    end
  end

  def entries
    @entries ||= Dir["#{@root}/**/*"].reject! {|entry| File.directory?(entry)}.collect {|entry| Entry.new(@root, entry.sub(@root + '/', ''))}
  end
  
  def opf
    @opf ||= entries.select {|entry| entry.name =~ /.*\.opf$/}.first
  end
    
  private

  def entryWithHref(href)
    entry = @entries.select {|entry| entry.href == href}.first
	entry = @entries.select {|entry| entry.href == "#{opf.dirname}/#{href}"}.first unless entry
	entry
  end

  def entryWithId(id)
    @entries.select {|entry| entry.id == id}.first
  end
  
  def raiseParseException(reason)
	raise "Book #{@filepath} cannot be opened because the OPF file could not be parsed:\n\n#{reason}."
  end

end
