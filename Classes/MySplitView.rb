class MySplitView < NSSplitView
  
  def initWithCoder(coder)
    super
    self
  end
  
  def dividerThickness
    1.0
  end

  def drawDividerInRect(rect)
    NSColor.whiteColor.set
    NSRectFill(rect)
  end
        
end