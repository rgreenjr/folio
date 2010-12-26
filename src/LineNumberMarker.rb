class LineNumberMarker < NSRulerMarker

  attr_accessor :lineNumber, :message

  def initWithRulerView(rulerView, lineNumber:lineNumber, message:message)
    initWithRulerView(rulerView, markerLocation:0.0, image:rulerView.markerImage, imageOrigin:rulerView.markerImageOrigin)
    @lineNumber = lineNumber
    @message = message
    self
  end

end
