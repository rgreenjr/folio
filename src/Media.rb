class Media
  
  TPYE_HASH = {
    "css"   => "text/css",
    "gif"   => "image/gif",
    "htm"   => "text/html",
    "html"  => "text/html",
    "jpg"   => "image/jpeg",
    "jpeg"  => "image/jpeg",
    "png"   => "image/png",
    "txt"   => "text/plain",
    "pdf"   => "application/pdf",
    "svg"   => "image/svg+xml",
    "xml"   => "application/xml",
    "xhtml" => "application/xhtml+xml",
  }
  
  def self.guessType(extension)
    TPYE_HASH[extension.gsub(/^\./, "")] || "unknown"
  end
  
  def self.types
    TPYE_HASH.values.sort
  end
  
end