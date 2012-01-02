class Image

  def self.imageRepTypeForFilename(filename)
    case filename.pathExtension
    when "tif"
      NSTIFFFileType
    when "tiff"
      NSTIFFFileType
    when "jpg"
      NSJPEGFileType
    when "jpeg"
      NSJPEGFileType
    when "jp2"
      NSJPEG2000FileType
    when "gif"
      NSGIFFileType
    when "png"
      NSPNGFileType
    when "bmp"
      NSBMPFileType
    when "png"
      NSPNGFileType
    else
      nil
    end
  end
  
  def self.warningCompositeImage(bottomImage)
    rect = NSMakeRect(0, 0, 16, 16)
    compositeImage = NSImage.alloc.initWithSize(rect.size)
    compositeImage.lockFocus
    bottomImage.drawInRect(rect, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)
    warningImage = NSImage.imageNamed("warning.png")
    warningImage.drawInRect(rect, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)
    compositeImage.unlockFocus
    compositeImage    
  end

end

class NSImage

  def imageRepForFilename(filename)
    repType = Image.imageRepTypeForFilename(filename)
    imageRep = NSBitmapImageRep.imageRepWithData(self.TIFFRepresentation)
    imageRep.representationUsingType(repType, properties:{ NSImageCompressionFactor => 1.0 })
  end

end
