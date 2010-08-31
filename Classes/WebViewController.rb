class WebViewController

  attr_accessor :webView, :item

  def awakeFromNib
    # @webView.resourceLoadDelegate = self
    @webView.editable = true
  end

  def item=(item)
    @item = item
    url = NSURL.URLWithString(@item.uri.to_s)
    request = NSURLRequest.requestWithURL(url)
    @webView.mainFrame.loadRequest(request)
  end

end