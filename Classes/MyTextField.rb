class MyTextField < NSTextField

  # Fix for Xcode bug that prevents NSTextFields from issuing 
  # text delegate method calls when they are inside a NSTeableCellView.
  # Also prevents NSTextFields from entering edit mode on right clicks.
  def acceptsFirstResponder
    event = NSApp.currentEvent
    return false if event && event.type == NSRightMouseDown
    return delegate.textShouldBeginEditing(self) if delegate
    super
  end
  
end