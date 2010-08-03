require "rexml/document"
require "erb"

class Book

  attr_accessor :title, :creator, :rights, :date, :publisher, :language
  attr_accessor :subject, :description, :identifier, :items, :spine, :references, :navigation


  def initialize(filepath)
    @spine = []
    @filepath = filepath
    @root = "/Users/rgreen/Desktop/extract"
    @rootURL = NSURL.URLWithString("file://#{@root}")
    FileUtils.rm_rf(@root)
    Dir.mkdir(@root)
    system("unzip -q -d '#{@root}' '#{@filepath}'")
    parse_opf
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
    puts "parsing opf..."
    opf = entries.select {|entry| entry.name =~ /.*content\.opf$/}.first
    raise "Book #{@filepath} cannot be opened because it is missing its content.opf file." unless opf
    doc = REXML::Document.new(opf.content)
    parse_metadata(doc)
    parse_manifest(doc)
    parse_spine(doc)
    parse_guide(doc)
    p @spine[0]
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
      entry.id = element.attributes["id"]
      entry.mediaType = element.attributes["media-type"]
    end
  end

  def parse_spine(doc)
    doc.elements.each("/package/spine/itemref") do |element|
      @spine << entryWithId(element.attributes["idref"])
    end
  end

  def parse_guide(doc)
    puts "parse_guide"
    doc.elements.each("/package/guide/reference") do |element|
      entry = entryWithHref(element.attributes["href"])
      entry.referenceTitle = element.attributes["title"]
      entry.referenceType = element.attributes["type"]
    end
  end

  def entries
    @entries ||= Dir["#{@root}/**/*"].reject! {|entry| File.directory?(entry)}.collect {|entry| Entry.new(@root, entry.sub(@root + '/', ''))}
  end

  private

  def entryWithHref(href)
    @entries.select {|entry| entry.href == href}.first
  end

  def entryWithId(id)
    @entries.select {|entry| entry.id == id}.first
  end

end
