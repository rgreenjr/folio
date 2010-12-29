class WebViewController

  attr_accessor :webView, :item, :bookController

  def awakeFromNib
    @webView.editable = false
    @webView.preferences.defaultFontSize = 16
    @webView.preferences.usesPageCache = false
    @webView.setUIDelegate(self)
    @webView.setPolicyDelegate(self)
  end

  def item=(item)
    return if item == @item
    @item = item
    if @item
      request = NSURLRequest.requestWithURL(@item.url)
      @webView.mainFrame.loadRequest(request)
    else
      @webView.mainFrame.loadHTMLString('', baseURL:nil)
    end
  end

  def back(sender)
    @webView.goBack(sender)
  end

  def forward(sender)
    @webView.goForward(sender)
  end

  def reload(sender)
    @webView.reload(nil)
  end

  def validateUserInterfaceItem(menuItem)
    @item != nil
  end

  def webView(sender, contextMenuItemsForElement:element, defaultMenuItems:defaultMenuItems)
    menuItems = defaultMenuItems.mutableCopy
    unsupported = menuItems.select { |item| unsupportedMenuTags.include?(item.tag) }
    unsupported.each { |item| menuItems.delete(item) }

    # menuItem = NSMenuItem.alloc.init
    # menuItem.title = "Create Navigation Link"
    # menuItem.target =self
    # menuItem.action ="createNavigationLink:"
    # menuItems.addObject(menuItem)

    menuItems
  end

  def webView(webView, decidePolicyForNavigationAction:actionInformation, request:request, frame:frame, decisionListener:listener)
    if request.URL.remote?
      listener.ignore
      system("open #{request.URL.absoluteString}")
    elsif @item.nil?
      listener.use
    else
      href = request.URL.path
      fragment = request.URL.fragment || ""
      item = @bookController.book.manifest.itemWithHref(href)
      if item.nil?
        listener.ignore
        alert = NSAlert.alloc.init
        alert.addButtonWithTitle "OK"
        alert.messageText = "Cannot Open Link"
        alert.informativeText = "The link could not be opened:\n\n#{request.URL.path}\n\nPlease make sure the referenced file is included in the manifest."
        alert.runModal
      elsif @item.name == item.name
        listener.use
      else
        listener.ignore
        point = Point.new(item)
        point.fragment = fragment
        @bookController.tabView.add(point)
      end
    end
  end

  private

  def unsupportedMenuTags
    @unsupportedMenuTags ||= [
      WebMenuItemTagOpenLinkInNewWindow, WebMenuItemTagDownloadLinkToDisk, WebMenuItemTagOpenImageInNewWindow,
      WebMenuItemTagDownloadImageToDisk, WebMenuItemTagOpenFrameInNewWindow, WebMenuItemTagOpenWithDefaultApplication
    ]
  end

end

