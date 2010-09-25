class SearchController
  
  attr_accessor :book, :searchField, :tableView, :webViewController, :textViewController
  
  def awakeFromNib
    @matches = []
    @tableView.delegate = self
    @tableView.dataSource = self
  end

  def book=(book)
    @book = book
    @tableView.reloadData
  end

  def search(sender)
    query = searchField.stringValue
    item = @textViewController.item
    return unless query && !query.empty? && item
    content = item.content
    offset = 0
    @matches = []
    while index = content.index(/#{query}/, offset)
      @matches << index.to_s
      offset += query.size + index
    end
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    return 0 unless @tableView.dataSource && @book # guard against SDK bug
    @matches ? @matches.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @matches[index]
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    string = @matches[@tableView.selectedRow]
    # @webViewController.item = item
    # @textViewController.item = item
  end

end