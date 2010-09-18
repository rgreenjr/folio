class SpineController

  attr_accessor :book, :tableView, :webViewController, :textViewController

  def awakeFromNib
    @tableView.delegate = self
    @tableView.dataSource = self
  end

  def book=(book)
    @book = book
    @tableView.reloadData
  end

  def numberOfRowsInTableView(aTableView)
    return 0 unless @tableView.dataSource && @book # guard against SDK bug
    @book.spine ? @book.spine.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @book.spine[index].name
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    item = @book.spine[@tableView.selectedRow]
    @webViewController.item = item
    @textViewController.item = item
  end
  
  def addPage(sender)
    index = @tableView.selectedRow
    index = @book.spine.size if index < 0
    item = Item.new("file://#{@book.container.root}/NewPage.xhtml", "#{@book.container.base}/NewPage.xhtml", Item.uuid, 'application/xhtml+xml')
    item.content = ''
    @book.spine.insert(index, item)
    @tableView.reloadData
  end
  
end