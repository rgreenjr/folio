class GotoLineController < NSWindowController
  
  attr_accessor :gotoLineField, :target
  
  def init
    initWithWindowNibName("GotoLine")
  end

  def showWindowWithTarget(sender)
    window # force window to load
    @target = sender
    window.center
    @gotoLineField.selectText(self)
    window.makeKeyAndOrderFront(self)
  end

  def gotoLine(sender)
    lineNumber = @gotoLineField.stringValue.to_i
    @target.gotoLineNumber(lineNumber)
    window.performClose(self)
  end

end