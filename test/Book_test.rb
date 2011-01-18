require 'test/unit'

class BookTest < Test::Unit::TestCase
  
  def test_new
    error = Pointer.new(:id)
    @book = Book.alloc.initWithType("epub", error:error)
    assert(@book, "Book.alloc.initWithType failed")
    assert_equal("untitled", @book.metadata.title)
  end
  
  def test_read
    filepath = File.join(File.expand_path(File.dirname(__FILE__)), "../data/The Fall of the Roman Empire.epub")
    fileURL = NSURL.fileURLWithPath(filepath)
    @book = Book.alloc.init
    error = Pointer.new(:id)
    success = @book.readFromURL(fileURL, ofType:"epub", error:error)
    errorMessage = success ? "" : error[0].localizedDescription
    assert(success, errorMessage)
  end
  
end
