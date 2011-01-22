class IssueViewController < NSViewController

  attr_accessor :bookController, :tableView, :headerView

  def initWithBookController(bookController)
    initWithNibName("IssueView", bundle:nil)
    @bookController = bookController
    self
  end

  def awakeFromNib
    @headerView.title = "Issues"

    imageCell = ImageCell.new
    imageCell.setEditable(false)
    @tableView.tableColumns.first.dataCell = imageCell

    @tableView.delegate = self
    @tableView.dataSource = self

    NSNotificationCenter.defaultCenter.addObserver(self, selector:"tabViewSelectionDidChange:", name:"TabViewSelectionDidChange", object:@bookController.tabViewController.view)
    NSNotificationCenter.defaultCenter.addObserver(self, selector:"itemMarkersDidChange:", name:"ItemMarkersDidChange", object:nil)
  end

  def tabViewSelectionDidChange(notification)
    @item = notification.object.selectedTab ? notification.object.selectedTab.item : nil
    @tableView.reloadData
  end

  def itemMarkersDidChange(notification)
    @tableView.reloadData if notification.object == @item
  end

  def numberOfRowsInTableView(tableView)
    @tableView.dataSource && @item ? @item.markers.size : 0
  end

  def tableView(tableView, objectValueForTableColumn:column, row:index)
    @item.markers[index].displayString
  end

  def tableViewSelectionDidChange(notification)
    if @tableView.selectedRow >= 0
      lineNumber = @item.markers[@tableView.selectedRow].lineNumber + 1
      @bookController.textViewController.lineNumberView.selectLineNumber(lineNumber)
    end
  end

  def tableView(outlineView, willDisplayCell:cell, forTableColumn:tableColumn, row:row)
    cell.font = NSFont.systemFontOfSize(11.0)
    # cell.image = NSWorkspace.sharedWorkspace.iconForFileType(File.extname(@item[row].name))
  end

end
