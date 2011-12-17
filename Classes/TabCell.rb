class TabCell < NSView

  LABEL_PADDING  = 10.0
  BUTTON_PADDING = 10.0

  attr_accessor :item
  attr_accessor :selected
  attr_accessor :closeButtonPressed
  attr_accessor :hovering

  def initialize(item)
    @item = item

    @backgroundImage = NSImage.imageNamed("tab-bg.png")
    @backgroundSelectedImage = NSImage.imageNamed("tab-selected-bg.png")
    @backgroundHoverImage = NSImage.imageNamed("tab-hover-bg.png")

    style = NSMutableParagraphStyle.alloc.init
    style.alignment = NSCenterTextAlignment
    style.lineBreakMode = NSLineBreakByTruncatingTail
    @labelAttributes = {
	    NSParagraphStyleAttributeName  => style,
	    NSFontAttributeName            => NSFont.systemFontOfSize(11.0),
	    NSForegroundColorAttributeName => NSColor.blackColor
	  }

	  @borderColor = NSColor.colorWithDeviceRed(0.535, green:0.535, blue:0.535, alpha:1.0)

	  @closeImage = NSImage.imageNamed('tab-close.png')
	  @closePressedImage = NSImage.imageNamed('tab-close-pressed.png')

	  @editedClosedImage = NSImage.imageNamed('tab-edited-close.png')
	  @editedPressedImage = NSImage.imageNamed('tab-edited-pressed.png')
  end
  
  def acceptsFirstResponder
    false
  end

  def drawRect(rect)
    drawBackground(rect)
    drawBorder(rect)
    drawLabel(rect)
    drawButton(rect)
  end

  def closeButtonHit?(point, rect)
    buttonRect = NSMakeRect(rect.origin.x + (BUTTON_PADDING * 0.5), (rect.size.height * 0.5) - (buttonImage.size.height * 0.5), buttonImage.size.width, buttonImage.size.height)
    NSPointInRect(point, buttonRect)
  end
  
  def save
    @item.save
  end

  def selected?
    @selected
  end

  def edited?
    @item.edited?
  end

  # each tab has its own NSUndoManager to isolate NSTextView undo stacks
  def undoManager
    @undoManager ||= NSUndoManager.alloc.init
  end

  private

  def drawBackground(rect)
    rect.size.width -= 1.0
    imageRect = NSMakeRect(0, 0, @backgroundImage.size.width, @backgroundImage.size.height)
    if @selected
      @backgroundSelectedImage.drawInRect(rect, fromRect:imageRect, operation:NSCompositeSourceOver, fraction:1.0)
    elsif @hovering
      @backgroundHoverImage.drawInRect(rect, fromRect:imageRect, operation:NSCompositeSourceOver, fraction:1.0)
    else
      @backgroundImage.drawInRect(rect, fromRect:imageRect, operation:NSCompositeSourceOver, fraction:1.0)
    end
  end

  def drawBorder(rect)
    @borderColor.set
    NSBezierPath.defaultLineWidth = 1.0
    NSBezierPath.strokeLineFromPoint(CGPoint.new(rect.origin.x + rect.size.width + 0.5, rect.origin.y), toPoint:CGPoint.new(rect.origin.x + rect.size.width + 0.5, rect.size.height))
  end

  def buttonImage
    if @closeButtonPressed
      edited? ? @editedPressedImage : @closePressedImage
    else
      edited? ? @editedClosedImage : @closeImage
    end
  end

  def drawLabel(rect)
    labelRect = NSInsetRect(rect, LABEL_PADDING, 0.0)
    labelRect.origin.x += BUTTON_PADDING
    labelRect.size.width -= BUTTON_PADDING
    labelSize = @item.name.sizeWithAttributes(@labelAttributes)
    labelRect.origin.y -= ((rect.size.height - labelSize.height) * 0.5).floor
    @item.name.drawInRect(labelRect, withAttributes:@labelAttributes)
  end

  def drawButton(rect)
    buttonPoint = CGPoint.new(rect.origin.x + (BUTTON_PADDING * 0.5), ((rect.size.height - buttonImage.size.height) * 0.5).floor)
    buttonImage.compositeToPoint(buttonPoint, operation:NSCompositeSourceOver)
  end

end
