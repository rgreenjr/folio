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
  
end