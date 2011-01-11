class WebViewController < NSViewController

  attr_accessor :item, :tabViewController

  def awakeFromNib
    view.editable = false
    view.frameLoadDelegate = self
    view.preferences.defaultFontSize = 16
    view.preferences.usesPageCache = false
    view.setUIDelegate(self)
    view.setPolicyDelegate(self)
  end

  def item=(item)
    return if item == @item
    @item = item
    if @item
      request = NSURLRequest.requestWithURL(@item.url)
      view.mainFrame.loadRequest(request)
    else
      view.mainFrame.loadHTMLString('', baseURL:nil)
    end
  end

  def back(sender)
    view.goBack(sender)
  end

  def forward(sender)
    view.goForward(sender)
  end

  def reload(sender)
    view.reload(nil)
  end

  def validateUserInterfaceItem(menuItem)
    @item != nil
  end

  def webView(sender, contextMenuItemsForElement:element, defaultMenuItems:defaultMenuItems)
    menuItems = defaultMenuItems.mutableCopy
    unsupported = menuItems.select { |item| unsupportedMenuTags.include?(item.tag) }
    unsupported.each { |item| menuItems.delete(item) }
    
    puts element[WebElementDOMNodeKey]

    menuItem = NSMenuItem.alloc.init
    menuItem.title = "Create Navigation Link"
    menuItem.target =self
    menuItem.action ="createNavigationLink:"
    menuItems.addObject(menuItem)

    menuItems
  end
  
  def createNavigationLink(sender)
    puts "createNavigationLink"
    # @bookWindowController.document.navigationController.addPoint(nil)
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
      targetItem = NSDocumentController.sharedDocumentController.currentDocument.manifest.itemWithHref(href)
      if targetItem.nil?
        listener.ignore
        Alert.runModal("Cannot Open Link", "Please make sure the file is included in the manifest.\n\n#{request.URL.path}")
      elsif @item.name == targetItem.name
        listener.use
      else
        listener.ignore
        point = Point.new(targetItem)
        point.fragment = fragment
        @tabViewController.addItemOrPoint(point)
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

