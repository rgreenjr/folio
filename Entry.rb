class Entry

  attr_accessor :base, :href, :content, :id, :mediaType, :referenceTitle, :referenceType

  def initialize(base, href)
    @base, @href = base, href
  end

  def name
	href.split('/').last
  end

  def content
    @content ||= File.read("#{fullpath}")
  end

  def content=(content)
    @content = content
    File.open(fullpath, 'wb') {|f| f.puts @content}
  end
  
  def dirname
	File.dirname(href)
  end

  def url
    "file://#{fullpath}"
  end

  def text?
    ['.xml', '.html', '.xhtml', '.htm', '.txt', '.css', '.opf', '.ncx', '.plist'].include?(File.extname(name))
  end

  def tidyable?
    ['.xml', '.xhtml', '.html', '.htm'].include?(File.extname(name))
  end

  def renderable?
    ['.xml', '.html', '.xhtml', '.htm', '.txt', '.jpg', '.jpeg', '.gif', '.svg', '.png'].include?(File.extname(name))
  end
  
  def tidy
	@content = `tidy -iq -raw -wrap 0 --tidy-mark no -f /Users/rgreen/Desktop/extract/tidy_errors.txt '#{fullpath}'`
  end

  private

  def fullpath
    "#{@base}/#{href}"
  end

end