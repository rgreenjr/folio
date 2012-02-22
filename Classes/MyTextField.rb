class MyTextField < NSTextField

  # Fix for Xcode bug that prevents NSTextFields from issuing 
  # text delegate method calls when they are inside a NSTableCellView.
  # Also prevents NSTextFields from entering edit mode on right clicks.
  def acceptsFirstResponder
    event = NSApp.currentEvent
    if event and event.type == NSRightMouseDown
      false
    elsif delegate and delegate.respond_to? "textShouldBeginEditing:"
      delegate.textShouldBeginEditing(self)
    else
      super
    end
  end
  
end