class ImageWell < NSImageView
  
  DEFAULT_IMAGE_NAME = "cover.jpg"

  attr_accessor :bookController
  attr_accessor :metadataController
  attr_accessor :imagePath

  def draggingEntered(draggingInfo)
    imageURL = extractImageURL(draggingInfo)
    imageURL && Image.imageRepTypeForFilename(imageURL.path) ? NSDragOperationCopy : NSDragOperationNone
  end

  def performDragOperation(draggingInfo)
    dragSucceeded = super
    if dragSucceeded
      imageURL = extractImageURL(draggingInfo)
      imageData = imageURL.resourceDataUsingCache(false)
      image = NSImage.alloc.initWithData(imageData)
      dragSucceeded = stashImage(image, imageURL.path.lastPathComponent)
    end
    dragSucceeded
  end
  
  def paste(sender)
    options = {}
    classArray = [NSImage]
    pasteboard = NSPasteboard.generalPasteboard
    if pasteboard.canReadObjectForClasses(classArray, options:options)
      imageArray = pasteboard.readObjectsForClasses(classArray, options:options)
      if stashImage(imageArray[0], @bookController.document.container.package.manifest.root.generateUniqueChildName(DEFAULT_IMAGE_NAME))
        self.image = imageArray[0]
        @metadataController.imageWellReceivedImage(self)
      end
    end
  end
  
  def imageName
    @imagePath ? @imagePath.lastPathComponent : nil
  end
  
  private
  
  def stashImage(image, filename)
    return false unless image && filename
    @imagePath = File.join(Dir.mktmpdir("folio-cover-image-"), filename)
    imageData = image.imageRepForFilename(filename)
    imageData && imageData.writeToFile(@imagePath, atomically:false)
  end
  
  def extractImageURL(draggingInfo)
    imageURL = nil
    xmlString = draggingInfo.draggingPasteboard.stringForType(NSURLPboardType)
    if xmlString
      data = xmlString.dataUsingEncoding(NSUTF8StringEncoding)
      urls = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption:NSPropertyListImmutable, format:nil, errorDescription:nil)
      imageURL = NSURL.URLWithString(urls[0]) unless urls.empty?
    end
    imageURL
  end
  
end
