class ImageCell < NSTextFieldCell

  PADDING = 4

  attr_accessor :image

  def selectWithFrame(cellFrame, inView:controlView, editor:textObj, delegate:anObject, start:selStart, length:selLength)
    imageFrame, textFrame, cellFrame = divideFrame(cellFrame) if @image
    super
  end

  def drawWithFrame(cellFrame, inView:controlView)
    if @image
      imageFrame, textFrame, cellFrame = divideFrame(cellFrame)

      if self.drawsBackground
        self.backgroundColor.set
        NSRectFill(imageFrame)
      end

      imageFrame[0] = [[imageFrame[0].origin.x + PADDING, imageFrame[0].origin.y], @image.size]

      if controlView.isFlipped
        delta = ((textFrame[0].size.height + imageFrame[0].size.height) / 2).ceil
      else
        delta = ((textFrame[0].size.height - imageFrame[0].size.height) / 2).ceil
      end
      imageFrame[0] = [[imageFrame[0].origin.x, imageFrame[0].origin.y + delta], imageFrame[0].size]

      @image.compositeToPoint(imageFrame[0].origin, operation:NSCompositeSourceOver)
    end
    super
  end

  private

  def divideFrame(cellFrame)
    textFrame = Pointer.new(NSRect.type)
    imageFrame = Pointer.new(NSRect.type)
    NSDivideRect(cellFrame, imageFrame, textFrame, 2 * PADDING + @image.size.width, NSMinXEdge)
    [imageFrame, textFrame, textFrame[0]]
  end

end