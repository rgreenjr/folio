class ProgressController < NSWindowController
  
  attr_accessor :progressBar, :progressText
  
  def init
    initWithWindowNibName("Progress")
  end

  def showWindow(title)
    begin
      @progressText.stringValue = title
      @progressBar.usesThreadedAnimation = true
      @progressBar.startAnimation(self)
      window.makeKeyAndOrderFront(self)
      yield
    ensure
      window.orderOut(self)
      @progressBar.stopAnimation(self)
    end
  end

end
