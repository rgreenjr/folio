class WebViewController

  attr_accessor :webView, :item

  def awakeFromNib
    @webView.editable = false
    @webView.preferences.defaultFontSize = 16
  end

  def item=(item)
    @item = item
    if @item
      request = NSURLRequest.requestWithURL(NSURL.URLWithString(@item.uri.to_s))
      @webView.mainFrame.loadRequest(request)
    else
      @webView.mainFrame.loadHTMLString('', baseURL:nil)
    end
  end

end