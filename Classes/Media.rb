class Media

  CSS       = "text/css"
  DIRECTORY = "directory"
  GIF       = "image/gif"
  HTML      = "application/xhtml+xml"
  JPG       = "image/jpeg"
  PNG       = "image/png"
  NCX       = "application/x-dtbncx+xml"
  OTF       = "font/opentype",
  PDF       = "application/pdf"
  SVG       = "image/svg+xml"
  TTF       = "application/x-font-ttf"
  TIFF      = "image/tiff"
  TXT       = "text/plain"
  XPGT      = "application/vnd.adobe-page-template+xml"
  XML       = "application/xml"
  
  MEDIA_TYPES_HASH = {
    "css"   => CSS,
    "ttf"   => TTF,
    "gif"   => GIF,
    "htm"   => HTML,
    "html"  => HTML,
    "jpg"   => JPG,
    "jpeg"  => JPG,
    "png"   => PNG,
    "otf"   => OTF,
    "pdf"   => PDF,
    "svg"   => SVG,
    "tif"   => TIFF,
    "tiff"  => TIFF,
    "txt"   => TXT,
    "xpgt"  => XPGT,
    "xhtml" => HTML,
    "xml"   => XML,
  }
  
  # returns best guess media type based on specified extension
  def self.guessType(extension)
    MEDIA_TYPES_HASH[extension.gsub(/^\./, '')] || ''
  end

  # returns closest media type based on specified string
  def self.closestType(string)
    self.types.find {|type| type.match(/^#{string}/i)}
  end
  
  def self.types
    MEDIA_TYPES_HASH.values.sort
  end
  
  def self.editable?(mediaType)
    [XML, HTML, CSS, NCX].include?(mediaType)
  end
  
  def self.renderable?(mediaType)
    [XML, HTML, JPG, PNG, GIF, SVG, CSS].include?(mediaType)
  end
  
  def self.imageable?(mediaType)
    [JPG, PNG, GIF, SVG, TIFF].include?(mediaType)
  end
  
  def self.flowable?(mediaType)
    [XML, HTML].include?(mediaType)
  end
  
  def self.formatable?(mediaType)
    [XML, HTML].include?(mediaType)
  end

  def self.ncx?(mediaType)
    mediaType == NCX
  end

  def self.directory?(mediaType)
    mediaType == DIRECTORY
  end

end