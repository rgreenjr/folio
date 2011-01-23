class IssueViewController < NSViewController

  attr_accessor :bookController, :outlineView, :headerView, :noIssuesImageView

  def initWithBookController(bookController)
    initWithNibName("IssueView", bundle:nil)
    @bookController = bookController
    @items = []
    self
  end

  def awakeFromNib
    @headerView.title = "Issues"

    imageCell = ImageCell.new
    imageCell.editable = false
    imageCell.selectable = false
    @outlineView.tableColumns.first.dataCell = imageCell

    @outlineView.delegate = self
    @outlineView.dataSource = self

    showNoIssuesImage

    NSNotificationCenter.defaultCenter.addObserver(self, selector:"itemMarkersDidChange:", name:"ItemMarkersDidChange", object:nil)
  end
  
  def refresh
    @items = @bookController.document.manifest.select { |item| item.hasMarkers? }
    @items.empty? ? showNoIssuesImage : showIssuesView
    @outlineView.deselectAll(self)
    @outlineView.reloadData
  end
  
  def itemMarkersDidChange(notification)
    refresh
  end
  
  def showNoIssuesImage
    @outlineView.hidden = true
    @noIssuesImageView.hidden = false
  end
  
  def showIssuesView
    @outlineView.hidden = false
    @noIssuesImageView.hidden = true
  end

  def outlineView(outlineView, numberOfChildrenOfItem:object)
    return 0 unless @outlineView.dataSource
    object ? object.markers.size : @items.size
  end

  def outlineView(outlineView, isItemExpandable:object)
    object.class == Item
  end

  def outlineView(outlineView, child:index, ofItem:object)
    object ? object.markers[index] : @items[index]
  end

  def outlineView(outlineView, objectValueForTableColumn:tableColumn, byItem:object)
    object.class == Item ? object.name : object.displayString
  end

  def outlineViewSelectionDidChange(notification)
    object = @outlineView.itemAtRow(@outlineView.selectedRow)
    return unless object
    if object.class == Item
      @bookController.tabViewController.addObject(object)
    else
      @bookController.tabViewController.addObject(@outlineView.parentForItem(object))
      object.ruler.selectLineNumber(object.lineNumber + 1)
    end
  end

  def outlineView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, item:item)
    cell.font = NSFont.systemFontOfSize(11.0)
    if item.class == Item
      # cell.badgeCount = item.markers.size
      cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(item.name))
    else
      cell.badgeCount = nil
      cell.image = NSImage.imageNamed('yield.png')
    end
  end

end
