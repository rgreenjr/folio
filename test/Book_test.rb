require 'test/unit'

class BookTest < Test::Unit::TestCase
  
  def setup
    url = NSURL.fileURLWithPath(File.expand_path(File.dirname(__FILE__)) + "/../data/The Fall of the Roman Empire.epub")
    @book = Book.alloc.init
    error = Pointer.new(:id)
    unless @book.readFromURL(url, ofType:"epub", error:error)
      puts error[0].localizedDescription
    end
  end
  
end
