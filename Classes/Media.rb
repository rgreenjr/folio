class Media

  CSS       = "text/css"
  DIRECTORY = "directory"
  GIF       = "image/gif"
  HTML      = "application/xhtml+xml"
  JPG       = "image/jpeg"
  PNG       = "image/png"
  NCX       = "application/x-dtbncx+xml"
  OEBPS     = "application/oebps-package+xml"
  OPF       = "application/x-font-opentype"
  OTF       = "application/x-font-opentype"
  PDF       = "application/pdf"
  PMAP      = "application/oebps-page-map+xml"
  SVG       = "image/svg+xml"
  TTF       = "application/x-font-ttf"
  TIFF      = "image/tiff"
  TXT       = "text/plain"
  XPGT      = "application/vnd.adobe-page-template+xml"
  XML       = "application/xml"
  
  MEDIA_TYPES_HASH = {
    "css"   => CSS,
    "gif"   => GIF,
    "htm"   => HTML,
    "epub"  => EPUB,
    "html"  => HTML,
    "jpeg"  => JPG,
    "jpg"   => JPG,
    "jp2"   => JPG,
    "otf"   => OTF,
    "pdf"   => PDF,
    "png"   => PNG,
    "svg"   => SVG,
    "tif"   => TIFF,
    "tiff"  => TIFF,
    "ttf"   => TTF,
    "txt"   => TXT,
    "xhtml" => HTML,
    "xpgt"  => XPGT,
    "xml"   => XML,
  }
  
  # returns best guess media type based on specified extension
  def self.guessType(extension)
    MEDIA_TYPES_HASH[extension.gsub(/^\./, '')] || ''
  end

  # returns closest media type based on specified string
  def self.closestType(value)
    self.types.find {|type| type.match(/^#{value}/i)}
  end
  
  def self.types
    @types ||= MEDIA_TYPES_HASH.values.sort.uniq
  end
  
  def self.renderable?(mediaType)
    [XML, HTML, JPG, PNG, GIF, SVG, CSS, TXT, PMAP].include?(mediaType)
  end
  
  def self.imageable?(mediaType)
    [JPG, PNG, GIF, TIFF].include?(mediaType)
  end
  
  def self.textual?(mediaType)
    [XML, HTML, CSS, TXT, SVG, NCX, PMAP].include?(mediaType)
  end
  
  def self.parseable?(mediaType)
    [XML, HTML, SVG, PMAP, NCX].include?(mediaType)
  end
  
  def self.spineable?(mediaType)
    [XML, HTML].include?(mediaType)
  end
  
  def self.ncx?(mediaType)
    mediaType == NCX
  end

  def self.directory?(mediaType)
    mediaType == DIRECTORY
  end

  def self.validMediaType?(mediaType)
    (mediaType =~ /^[a-zA-Z0-9!#$&+-^_]+\/[a-zA-Z0-9!#$&+-^_]+$/) == 0
  end

end