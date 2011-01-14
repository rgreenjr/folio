class ImageWell < NSImageView

  attr_accessor :imageURL

  def performDragOperation(draggingInfo)
    dragSucceeded = super
    if dragSucceeded
      urlsXML = draggingInfo.draggingPasteboard.stringForType(NSURLPboardType)
      if urlsXML
        data = urlsXML.dataUsingEncoding(NSUTF8StringEncoding)
        urls = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption:NSPropertyListImmutable, format:nil, errorDescription:nil)
        @imageURL = urls.empty? ? nil : NSURL.URLWithString(urls[0])
        @imagePath = nil
      end
    end
    dragSucceeded
  end

  # TODO auto detect image type representation
  def imagePath
    return nil unless @imageURL
    unless @imagePath
      imageRep = image.representations[0]
      data = imageRep.representationUsingType(NSJPEGFileType, properties:nil)
      tmpDir = Dir.mktmpdir("folio-cover-image-")
      @imagePath = File.join(tmpDir, @imageURL.path.lastPathComponent)
      data.writeToFile(@imagePath, atomically:false)
    end
    @imagePath
  end

end
