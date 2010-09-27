class SearchController
  
  attr_accessor :book, :searchField, :outlineView, :webViewController, :textViewController
  
  def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
  end

  def book=(book)
    @book = book
    @search = nil
    @searchField.stringValue = ''
    @outlineView.reloadData
  end

  def search(sender)
    @search = Search.new(searchField.stringValue, book)
    @outlineView.reloadData
    @search.each {|match| @outlineView.expandItem(match, expandChildren:false) }
  end
  
  def outlineView(outlineView, numberOfChildrenOfItem:item)
    return 0 unless @search
    item ? item.size : @search.size
  end

  def outlineView(outlineView, isItemExpandable:item)
    item && !item.empty?
  end

  def outlineView(outlineView, child:index, ofItem:item)
    item ? item[index] : @search[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:item)
    item.message
  end

  def outlineViewItemDidExpand(notification)
    notification.userInfo['NSObject'].expanded = true
  end

  def outlineViewItemDidCollapse(notification)
    notification.userInfo['NSObject'].expanded = false
  end

  def outlineViewSelectionDidChange(notification)
    return if @outlineView.selectedRow < 0
    match = @search.walk(@outlineView.selectedRow)
    @textViewController.item = match.item
    # @webViewController.item = item
    if match.empty?
      @textViewController.textView.scrollRangeToVisible(match.range)
      @textViewController.textView.showFindIndicatorForRange(match.range)
    end
  end

end