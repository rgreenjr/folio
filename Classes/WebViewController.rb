class WebViewController < NSViewController

  attr_accessor :bookController
  
  # attr_accessor :item

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

  def validateUserInterfaceItem(interfaceItem)
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
      # URL is outside book, so we supress listener
      listener.ignore
      
      # open URL in user's default browser
      NSWorkspace.sharedWorkspace.openURL(request.URL)
      
    elsif @item.nil?
      # there is no current item (so there can be no match) so proceed
      listener.use
    else
      # get the path of the request
      href = request.URL.path
      
      # get fragment of request (if there is one)
      fragment = request.URL.fragment || ""
      
      # find matching item in manifest
      targetItem = @bookController.document.manifest.itemWithHref(href)      
      
      if targetItem.nil?
        # not match was found, so supress listener
        listener.ignore
        
        # get relativePath for error message
        relativePath = @bookController.document.relativePathFor(request.URL.path)
        
        # show alert message that item couldn't be found
        @bookController.runModalAlert("Could not open \"#{relativePath}\" because it could not be found.")
        
      elsif @item.item.name == targetItem.name
        
        # item was found and it matches the current item, so proceed
        listener.use
      else
        
        # item was found, but is different from current item, so we supress listener
        listener.ignore
        
        # create a new point from request (in case there is a fragement)
        point = Point.new(targetItem)
        
        # assign fragment
        point.fragment = fragment
        
        # open point in new tab
        @bookController.tabbedViewController.addObject(point)
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

