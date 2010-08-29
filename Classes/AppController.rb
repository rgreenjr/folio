class AppController
  
  attr_accessor :bookController
  
  def awakeFromNib
    bookController.book = Book.new("/Users/rgreen/Desktop/Folio/data/The Fall of the Roman Empire_ A New History of Rome and the Barbarians.epub")
  end
  
  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end
  
end