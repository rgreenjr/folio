class SpineController

  attr_accessor :spine, :tableView, :webViewController, :textViewController

  def awakeFromNib
    @tableView.delegate = self
    @tableView.dataSource = self
    @tableView.reloadData
  end

  def spine=(spine)
    @spine = spine
    @tableView.reloadData
  end

  def numberOfRowsInTableView(aTableView)
    @spine ? @spine.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @spine[index].name
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    item = @spine[@tableView.selectedRow]
    @webViewController.item = item
    @textViewController.item = item
  end

end