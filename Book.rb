require "rexml/document"
require "fileutils"
require "erb"

# http://www.hxa.name/articles/content/epub-guide_hxa7241_2007.html

class Book

  attr_accessor :title, :language, :identifier
  attr_accessor :creator, :contributor, :publisher, :subject, :description
  attr_accessor :date, :type, :format, :source, :relation, :coverage, :rights
  attr_accessor :spine, :navMap, :ncx, :container

  def initialize(filepath)
    @spine = []
    @filepath = filepath
    @root = "/Users/rgreen/Desktop/extract"
    FileUtils.rm_rf(@root)
    Dir.mkdir(@root)
    system("unzip -q -d '#{@root}' \"#{@filepath}\"")
    @container = Container.new(@root)
    @package = Package.new(self)
    @navMap = NavMap.new(@ncx)
    #puts @navMap.to_xml
  end
  
  def entries
    unless @entries
      dirs = Dir["#{@root}/**/*"].reject! {|entry| File.directory?(entry)}
      @entries = dirs.map {|entry| Entry.new(@root, entry.sub(@root + '/', ''))}
    end
    @entries
  end

  def save(directory)
    tmp = "/Users/rgreen/Desktop/tmp"
    FileUtils.rm_rf(tmp)
    FileUtils.mkdir_p(["#{tmp}/META-INF", "#{tmp}/OEBPS"])
    FileUtils.cp(NSBundle.mainBundle.pathForResource("mimetype", ofType:nil), "#{tmp}/mimetype")
    @container.save(tmp)
    @navMap.save(tmp)
    @package.save(self, @root, tmp)
    system("cd '#{tmp}'; zip -X0 '/Users/rgreen/Desktop/#{@title}.epub' mimetype")
    system("cd '#{tmp}'; zip -X9urD '#{directory}/#{@title}.epub' *")
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
    entry = entries.select {|entry| entry.href == "#{@container.root}/#{href}"}.first unless entry
    entry
  end

  def entryWithId(id)
    entries.select {|entry| entry.id == id}.first
  end
  
  private

  def raiseParseException(reason)
    raise "Book #{@filepath} cannot be opened because #{reason}."
  end

end
