class AppController

  attr_accessor :bookController

  def awakeFromNib
	bookController.book = Book.new("/Users/rgreen/Desktop/Folio/Fight Club.epub")
  end

  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end
  
end