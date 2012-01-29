class BitmapChecker
  
  def self.validate(item, issues=[])
    return unless item
    issues << Issue.new("The file \"#{item.name}\" does not appear to be of type #{item.mediaType}") unless validHeader?(item)
  end
  
  private
  
  def self.validHeader?(item)
    header = item.content.unpack("CCCC")
    case item.mediaType
    when Media::JPG
  		header[0] == 0xFF && header[1] == 0xD8
    when Media::GIF
  		header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x38
    when Media::PNG
  		header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47
		else
		  true
    end
  end
  
end
