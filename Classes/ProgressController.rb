class ProgressController < NSWindowController
  
  attr_accessor :progressBar, :progressText
  
  def init
    initWithWindowNibName("Progress")
  end

  def showWindowWithTitle(title)
    window # force window to load
    begin
      @progressText.stringValue = title
      @progressBar.usesThreadedAnimation = true
      @progressBar.startAnimation(self)
      window.makeKeyAndOrderFront(self)
      yield progressBar
    ensure
      window.orderOut(self)
      @progressBar.stopAnimation(self)
    end
  end

end
