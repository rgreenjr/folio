class MySplitView < NSSplitView
  
  def initWithCoder(coder)
    super
    puts "initWithCoder"
    
    @backgroundImage = NSImage.imageNamed("issues-divider-background.png")
        
    @rightButton = NSButton.alloc.init
    @rightButton.bezelStyle = NSRegularSquareBezelStyle
    @rightButton.bordered = false
    @rightButton.image = NSImage.imageNamed("issues-button-right.png")    
    @rightButton.alternateImage = NSImage.imageNamed("issues-button-right-alt.png")    
    @rightButton.buttonType = NSMomentaryChangeButton
    
    self
  end
  
  def dividerThickness
    22.0
  end

  def drawDividerInRect(rect)
    @backgroundImage.drawInRect(rect, fromRect:NSZeroRect, operation:NSCompositeSourceOver, fraction:1.0)
  end
        
end