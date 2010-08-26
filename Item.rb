require 'open-uri'

class Item
  
  attr_accessor :base, :fullpath, :content, :extname, :name, :url
  attr_accessor :id, :href, :mediaType, :referenceTitle, :referenceType
  
  def initialize(base, href, id, mediaType)
    @base = base
    @href = href
    @id = id
    @mediaType = mediaType
    @fullpath = "#{@base}/#{@href}"
    raise "File is missing: #{@href}" unless File.exists?(@fullpath)
    @url = URI.parse("file://#{@fullpath}")
    @name = @url.path.split('/').last
    @extname = File.extname(@name)
  end

  def content
    @content ||= File.read(@fullpath)
  end
  
  def content=(content)
    @content = content
    File.open(@fullpath, 'wb') {|f| f.puts @content}
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
  
  def manifestable?
    %w{.opf .ncx .plist}.include?(@extname) == false
  end
  
  def tidy
    return unless tidyable?
    self.content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{@fullpath}'`
  end
  
end