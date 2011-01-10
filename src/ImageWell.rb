class ImageWell < NSImageView

  attr_accessor :imagePath

  def performDragOperation(draggingInfo)
    dragSucceeded = super
    if dragSucceeded
      filenamesXML = draggingInfo.draggingPasteboard.stringForType(NSFilenamesPboardType)
      if filenamesXML
        data = filenamesXML.dataUsingEncoding(NSUTF8StringEncoding)
        filenames = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption:NSPropertyListImmutable, format:nil, errorDescription:nil)
        @imagePath = filenames.count >= 1 ? filenames[0] : nil
      end
    end
    dragSucceeded
  end

end
