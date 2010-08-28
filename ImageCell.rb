class ImageCell < NSTextFieldCell

  attr_accessor :image

  def selectWithFrame(aRect, inView:controlView, editor:textObj, delegate:anObject, start:selStart, length:selLength)
    # puts "selectWithFrame"
    if @image
      textFrame = Pointer.new(NSRect.type)
      imageFrame = Pointer.new(NSRect.type)
      NSDivideRect(aRect, imageFrame, textFrame, 3 + @image.size.width, NSMinXEdge)
      aRect = textFrame[0]
    end
    super
  end

  def drawWithFrame(cellFrame, inView:controlView)
    # puts "drawWithFrame"
    if @image
      textFrame = Pointer.new(NSRect.type)
      imageFrame = Pointer.new(NSRect.type)
      NSDivideRect(cellFrame, imageFrame, textFrame, 3 + @image.size.width, NSMinXEdge)

      if self.drawsBackground
        self.backgroundColor.set
        NSRectFill(imageFrame)
      end

      cellFrame = textFrame[0]
      imageFrame[0] = CGRect.new(CGPoint.new(imageFrame[0].origin.x + 3, imageFrame[0].origin.y), @image.size)

      if controlView.isFlipped
        delta = ((textFrame[0].size.height + imageFrame[0].size.height) / 2).ceil
      else
        delta = ((textFrame[0].size.height - imageFrame[0].size.height) / 2).ceil
      end
      imageFrame[0] = CGRect.new(CGPoint.new(imageFrame[0].origin.x, imageFrame[0].origin.y + delta), imageFrame[0].size)

      @image.compositeToPoint(imageFrame[0].origin, operation:NSCompositeSourceOver)
    end
    super
  end

end