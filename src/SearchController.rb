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
    regex = Regexp.new(query)
    content = @textViewController.item.content
    puts content
    @matches = regex.match(content)
    @matches.size.times do |i|
      p @matches[i]
      puts "matches.offset(#{i}) = #{@matches.offset(i)}"
    end
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    return 0 unless @tableView.dataSource && @book # guard against SDK bug
    @matches ? @matches.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @matches.begin(index).to_s
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    string = @matches[@tableView.selectedRow].to_s
    # @webViewController.item = item
    # @textViewController.item = item
  end

end