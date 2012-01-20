# class Thumbnail
# 
#   def initialize
#     rect = [100.0, 100.0, 100, 100]
#     @window = NSWindow.alloc.initWithContentRect(rect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)
#     @size = [1024, 0]
#     @webView = WebView.alloc.initWithFrame(rect)
#     @webView.mainFrame.frameView.allowsScrolling = false
#     @webView.frameLoadDelegate = self
#     @webView.frameSize = @size
#     @window.contentView = @webView
#     @window.contentSize = @size
#   end
# 
#   def capture(url)
#     @webView.mainFrame.loadRequest(NSURLRequest.requestWithURL(url))
#   end
# 
#   def webViewxxx(webView, didFinishLoadForFrame:frame)
#     viewport = @webView.mainFrame.frameView.documentView
#     @window.orderFront(nil)
#     @window.display
#     @window.contentSize = @size
#     viewport.frame = viewport.bounds
#     viewport.lockFocus
#     bitmap = NSBitmapImageRep.alloc.initWithFocusedViewRect(viewport.bounds)
#     viewport.unlockFocus
#     image = bitmap.representationUsingType(NSPNGFileType, properties:nil)
#     image.writeToFile("/Users/rgreen/Desktop/thumbnail.png", atomically:true)
#   end
# 
#   def webView(webView, didFinishLoadForFrame:frame)
#     @window.orderFront(nil)
#     @window.display
#     @webView.mainFrame.frameView.allowsScrolling = false
#     viewport = @webView.mainFrame.frameView.documentView
#     # viewport.window.contentSize = viewport.bounds.size
#     viewport.frame = viewport.bounds
#     viewport.lockFocus
# 
#     p viewport.bounds
# 
#     bitmap = NSBitmapImageRep.alloc.initWithFocusedViewRect(viewport.bounds)
#     puts bitmap
#     viewport.unlockFocus
#     # image = bitmap.representationUsingType(NSPNGFileType, properties:nil)
#     # image.writeToFile("/Users/rgreen/Desktop/thumbnail.png", atomically:true)
#   end
# 
# end

class Thumbnail
  attr_accessor :options, :web_view

  def initialize
    rect = [-16000.0, -16000.0, 100, 100]
    win = NSWindow.alloc.initWithContentRect(rect, styleMask:NSBorderlessWindowMask, backing:NSBackingStoreBuffered, defer:false)

    @web_view = WebView.alloc.initWithFrame rect
    @web_view.mainFrame.frameView.allowsScrolling = false
    @web_view.applicationNameForUserAgent = "ss"
    @web_view.frameLoadDelegate = self

    win.contentView = @web_view

    @options = {}
    @options[:width]  ||= 1024
    @options[:height] ||= 0
  end

  def capture(url)
    @web_view.window.contentSize = [@options[:width], @options[:height]]
    @web_view.frameSize = [@options[:width], @options[:height]]
    @web_view.mainFrame.loadRequest NSURLRequest.requestWithURL url
  end

  def webView(web_view, didFinishLoadForFrame:frame)
    viewport = web_view.mainFrame.frameView.documentView
    viewport.window.orderFront(nil)
    viewport.window.display
    viewport.window.contentSize = [@options[:width], (@options[:height] > 0 ? @options[:height] : viewport.bounds.size.height)]
    viewport.frame = viewport.bounds
    sleep(@options[:delay]) if @options[:delay]
    capture_and_save viewport
  end

  def capture_and_save(view)
    view.lockFocus
    bitmap = NSBitmapImageRep.alloc.initWithFocusedViewRect view.bounds
    view.unlockFocus

    image = bitmap.representationUsingType NSPNGFileType, properties:nil
    image.writeToFile("/Users/rgreen/Desktop/thumbnail.png", atomically:true)
  end
end
