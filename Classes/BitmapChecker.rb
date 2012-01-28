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
  		header[0] == 'G' && header[1] == 'I' && header[2] == 'F' && header[3] == '8'
    when Media::PNG
  		header[0] == 0x89 && header[1] == 'P' && header[2] == 'N' && header[3] == 'G'
		else
		  true
    end
  end
  
end
