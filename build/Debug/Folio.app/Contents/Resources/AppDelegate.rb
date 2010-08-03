class AppDelegate

  attr_accessor :bookController

  def awakeFromNib
	book = Book.new("/Volumes/Media/iTunes\ Media/Books/Michael\ Lewis/The\ Big\ Short_\ Inside\ the\ Doomsday\ Machine.epub")
	bookController.book = book
  end

  def applicationShouldTerminateAfterLastWindowClosed(application)
    true
  end

end