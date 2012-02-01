class Media

  CSS       = "text/css"
  DIRECTORY = "directory"
  EPUB      = "application/oebps-package+xml"
  GIF       = "image/gif"
  HTML      = "application/xhtml+xml"
  JPG       = "image/jpeg"
  PNG       = "image/png"
  NCX       = "application/x-dtbncx+xml"
  OPF       = "application/x-font-opentype"
  OTF       = "application/x-font-opentype"
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
    "jp2"   => JPG,
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
  def self.closestType(value)
    self.types.find {|type| type.match(/^#{value}/i)}
  end
  
  def self.types
    @types ||= MEDIA_TYPES_HASH.values.sort.uniq
  end
  
  def self.editable?(mediaType)
    [XML, HTML, CSS, TXT, SVG, NCX].include?(mediaType)
  end
  
  def self.renderable?(mediaType)
    [XML, HTML, JPG, PNG, GIF, SVG, CSS, TXT].include?(mediaType)
  end
  
  def self.imageable?(mediaType)
    [JPG, PNG, GIF, SVG, TIFF].include?(mediaType)
  end
  
  def self.flowable?(mediaType)
    [XML, HTML, TXT].include?(mediaType)
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

  def self.dtdPathForType(mediaType)
    case mediaType
    when Media::HTML
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/xhtml1-strict.dtd")
    when Media::NCX
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/ncx-2005-1.dtd")
    when Media::OPF
      File.join(NSBundle.mainBundle.bundlePath, "/Contents/Resources/opf20.dtd")
    else
      nil
    end
  end

end