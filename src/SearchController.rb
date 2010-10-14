class SearchController
  
  SEARCH_BOX_HEIGHT = 36.0

  attr_accessor :book, :searchField, :replaceField, :windowController
  attr_accessor :outlineView, :tabView, :textViewController, :searchBox

  def awakeFromNib
    @outlineView.delegate = self
    @outlineView.dataSource = self
    @searchField.delegate = self    
    @tabView.superview.addSubview(@searchBox, positioned:NSWindowBelow, relativeTo:@tabView)
  end

  def book=(book)
    @book = book
    @search = nil
    @searchField.stringValue = ''
    @outlineView.reloadData
  end

  def show(sender)    
    destination = @tabView.frame.origin.y - SEARCH_BOX_HEIGHT
    return if @searchBox.frame.origin.y == destination

    box = @tabView.superview

    splitView = @tabView.superview.subviews[2]    
    splitRect = splitView.frame
    splitRect.size.height = box.frame.size.height - @tabView.frame.size.height - SEARCH_BOX_HEIGHT
    splitView.animator.frame = splitRect
    
    # place at tabview
    searchRect = @tabView.frame
    searchRect.size.height = SEARCH_BOX_HEIGHT
    @searchBox.frame = searchRect

    # animate down
    searchRect.origin.y = destination
    @searchBox.animator.frame = searchRect
    
    @searchField.selectText nil
  end

  def hide(sender)
    box = @tabView.superview
    searchRect = @searchBox.frame
    searchRect.origin.y = @tabView.frame.origin.y
    @searchBox.animator.frame = searchRect
    splitView = @tabView.superview.subviews[2]
    splitRect = splitView.frame
    splitRect.size.height = box.frame.size.height - @tabView.frame.size.height
    splitView.animator.frame = splitRect
  end

  def search(sender)
    query = searchField.stringValue
    return unless query.size > 0
    @search = Search.new(searchField.stringValue, book)
    @outlineView.reloadData
    @windowController.showSearchResults
    # @search.each {|match| @outlineView.expandItem(match, expandChildren:false) }
  end
  
  # searchField delegate method
  def control(control, textView:textView, doCommandBySelector:command) 
    hide(nil) if command.to_s == "cancelOperation:"
    false
  end
  
  def previousMatch(sender)
    return unless @search && @search.size > 0
    row = @outlineView.selectedRow
    return if row - 1 < 0
    indices = NSIndexSet.indexSetWithIndex(row - 1)
    @outlineView.selectRowIndexes(indices, byExtendingSelection:false)
  end

  def nextMatch(sender)
    return unless @search && @search.size > 0
    row = @outlineView.selectedRow
    row = 0 if row < 0
    return if row + 1 >= @search.total
    indices = NSIndexSet.indexSetWithIndex(row + 1)
    @outlineView.selectRowIndexes(indices, byExtendingSelection:false)
  end

  def replace(sender)
    puts "replace"
    return unless @search && @search.size > 0
    replacement = replaceField.stringValue
    return if replacement.empty?
    row = @outlineView.selectedRow
    return unless row > 0
    match = @search.walk(row)
    return unless match.leaf?
    @textViewController.replace(match.range, replacement)
    puts "done"
    match.changed = true
    puts "changed"
    match.parent.each do |m|
      puts "sliding #{m.message} by #{replacement.size - match.range.length}"
      m.slide(replacement.size - match.range.length)
    end
  end

  def replaceAll(sender)
    puts "replaceAll"
    # replacement = replaceField.stringValue
    # return if replacement.empty?
    # @search.each do |match|
    #   @textViewController.replace(match.range, replacement) unless match.leaf?
    # end
  end

  def enableSearch
    @search && !@search.empty? && !replaceField.stringValue.empty?
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
    @tabView.add(match.item)
    if match.leaf?
      @textViewController.textView.scrollRangeToVisible(match.range)
      @textViewController.textView.showFindIndicatorForRange(match.range)
    end
  end

  def outlineView(outlineView, dataCellForTableColumn:tableColumn, item:match)
    match.leaf? ? NSTextFieldCell.alloc.init : ImageCell.new
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:match)
    cell.editable = false
    cell.selectable = false
    cell.font = NSFont.systemFontOfSize(11.0)
    unless match.leaf?
      cell.badgeCount = match.size
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(match.item.name))
    end
  end

end