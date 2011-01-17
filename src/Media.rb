class Media
  
  TYPE_HASH = {
    "css"   => "text/css",
    "ttf"   => "application/x-font-ttf",
    "gif"   => "image/gif",
    "htm"   => "text/html",
    "html"  => "text/html",
    "jpg"   => "image/jpeg",
    "jpeg"  => "image/jpeg",
    "png"   => "image/png",
    "otf"   => "font/otf",
    "pdf"   => "application/pdf",
    "svg"   => "image/svg+xml",
    "tif"   => "image/tiff",
    "tiff"  => "image/tiff",
    "txt"   => "text/plain",
    "xpgt"  => "application/vnd.adobe-page-template+xml",
    "xhtml" => "application/xhtml+xml",
    "xml"   => "application/xml",
  }
  
  def self.guessType(extension)
    TYPE_HASH[extension.gsub(/^\./, "")] || "unknown"
  end
  
  def self.types
    TYPE_HASH.values.sort
  end
  
  def self.editable?(mediaType)
    %w{application/xml application/xhtml+xml text/css application/x-dtbncx+xml}.include?(mediaType)
  end
  
  def self.renderable?(mediaType)
    %w{application/xml application/xhtml+xml image/jpeg image/png image/gif image/svg+xml text/css}.include?(mediaType)
  end
  
  def self.imageable?(mediaType)
    %w{image/jpeg image/png image/gif image/svg+xml image/tiff}.include?(mediaType)
  end
  
  def self.flowable?(mediaType)
    %w{application/xml application/xhtml+xml}.include?(mediaType)
  end
  
  def self.formatable?(mediaType)
    %w{application/xml application/xhtml+xml}.include?(mediaType)
  end

  def self.ncx?(mediaType)
    mediaType == "application/x-dtbncx+xml"
  end

end