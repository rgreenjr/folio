class ProgressController < NSWindowController
  
  attr_accessor :progressWindow, :progressBar, :progressText
  
  def init
    initWithWindowNibName("Progress")
  end

  def show(title)
    @progressText.stringValue = title
    @progressWindow.makeKeyAndOrderFront(self)
    @progressBar.usesThreadedAnimation = true
    @progressBar.startAnimation(self)
  end
  
  def hide
    @progressWindow.orderOut(self)
    @progressBar.stopAnimation(self)
  end
  
end
