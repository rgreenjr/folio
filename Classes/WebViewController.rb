class WebViewController

  attr_accessor :webView, :item

  def awakeFromNib
    # @webView.resourceLoadDelegate = self
  end

  def item=(item)
    @item = item
    url = NSURL.URLWithString(@item.uri)
    request = NSURLRequest.requestWithURL(url)
    @webView.mainFrame.loadRequest(request)
  end

end