class MyTextField < NSTextField

  # Fix for Xcode bug that prevents NSTextFields from issuing 
  # text delegate method calls when they are inside a NSTeableCellView.
  def acceptsFirstResponder
    delegate ? delegate.textShouldBeginEditing(self) : super
  end
  
end