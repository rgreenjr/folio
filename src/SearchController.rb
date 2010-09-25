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
    return unless query && !query.empty?
    @matches = []
    @book.manifest.each do |item|
      next unless item.editable?
      puts "searching #{item.href}"
      offset = 0
      while index = item.content.index(query, offset)
        puts "match index = #{index}"
        @matches << Match.new(item, query, index)
        offset = index + query.size
      end
      # break
    end
    puts "done"
    # @searchField.label = "#{@m}"
    @tableView.reloadData
  end
  
  def numberOfRowsInTableView(aTableView)
    return 0 unless @tableView.dataSource && @book # guard against SDK bug
    @matches ? @matches.size : 0
  end

  def tableView(aTableView, objectValueForTableColumn:column, row:index)
    @matches[index].message
  end

  def tableViewSelectionDidChange(aNotification)
    return if @tableView.selectedRow < 0
    match = @matches[@tableView.selectedRow]
    @textViewController.item = match.item
    @textViewController.textView.scrollRangeToVisible(match.range)
    @textViewController.textView.showFindIndicatorForRange(match.range)
    # @webViewController.item = item
  end

end