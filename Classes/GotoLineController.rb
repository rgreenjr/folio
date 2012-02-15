class GotoLineController < NSWindowController
  
  attr_accessor :gotoLineField
  attr_accessor :target
  
  def init
    initWithWindowNibName("GotoLine")
  end

  def showWindowWithTarget(sender)
    loadWindow
    window.center
    @target = sender
    @gotoLineField.selectText(self)
    window.makeKeyAndOrderFront(self)
  end

  def gotoLine(sender)
    lineNumber = @gotoLineField.stringValue.to_i
    @target.gotoLineNumber(lineNumber)
    window.performClose(self)
  end

end