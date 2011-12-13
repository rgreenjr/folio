class ImageWell < NSImageView

  attr_accessor :bookController
  attr_accessor :imagePath

  def performDragOperation(draggingInfo)
    dragSucceeded = super
    if dragSucceeded
      xml = draggingInfo.draggingPasteboard.stringForType(NSURLPboardType)
      if xml
        data = xml.dataUsingEncoding(NSUTF8StringEncoding)
        urls = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption:NSPropertyListImmutable, format:nil, errorDescription:nil)
        if urls.empty?
          dragSucceeded = false
        else
          imageURL = NSURL.URLWithString(urls[0])
          stashImage(NSImage.alloc.initWithData(imageURL.resourceDataUsingCache(false)), imageURL.path.lastPathComponent)
        end
      end
    end
    dragSucceeded
  end
  
  def paste(sender)
    options = {}
    classArray = [NSImage]
    pasteboard = NSPasteboard.generalPasteboard
    if pasteboard.canReadObjectForClasses(classArray, options:options)
      imageArray = pasteboard.readObjectsForClasses(classArray, options:options)
      stashImage(imageArray[0], @bookController.document.manifest.root.generateUniqueChildName("cover.jpg"))
      self.image = imageArray[0]
      @bookController.metadataController.imageWellReceivedImage(self)
    end
  end
  
  def imageName
    @imagePath ? @imagePath.lastPathComponent : nil
  end
  
  private
  
  def stashImage(newImage, filename)
    @imagePath = File.join(Dir.mktmpdir("folio-cover-image-"), filename)
    newImage.TIFFRepresentation.writeToFile(@imagePath, atomically:false)
  end

end
