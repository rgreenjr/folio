class Entry

  attr_accessor :root, :fullpath, :content, :dirname, :extname, :name, :url
  attr_accessor :id, :href, :mediaType, :referenceTitle, :referenceType

  def initialize(root, href)
    @root, self.href = root, href
  end

  def content
    @content ||= File.read("#{fullpath}")
  end

  def content=(content)
    @content = content
    File.open(fullpath, 'wb') {|f| f.puts @content}
  end
    
  def href=(href)
	@href = href
	@name = @href.split('/').last
	@dirname = File.dirname(@href)
	@extname = File.extname(@name)
	@fullpath = "#{@root}/#{@href}"
	@url = "file://#{@fullpath}"
  end

  def text?
    %w{.xml .html .xhtml .htm .txt .css .opf .ncx .plist}.include?(@extname)
  end

  def tidyable?
    %w{.xml .xhtml .html .htm}.include?(@extname)
  end

  def renderable?
    %w{.xml .html .xhtml .htm .txt .jpg .jpeg .gif .svg .png}.include?(@extname)
  end
  
  def tidy
	self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{@fullpath}'`
  end

end