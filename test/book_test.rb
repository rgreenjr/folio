require 'test/unit'

class BookTest < Test::Unit::TestCase
  
  def setup
    url = NSURL.fileURLWithPath(File.expand_path(File.dirname(__FILE__)) + "/../data/The Fall of the Roman Empire.epub")
    @book = Book.alloc.init
    error = Pointer.new_with_type('@')
    unless @book.readFromURL(url, ofType:"epub", error:error)
      puts error[0].localizedDescription
    end
  end
  
  def teardown
  end
  
  def test_title
    assert_equal("The Fall of the Roman Empire: A New History of Rome and the Barbarians", @book.metadata.title)
  end
  
  def test_language
    assert_equal("en", @book.metadata.language)
  end
  
  def test_creator
    assert_equal("Peter Heather", @book.metadata.creator)
  end
  
  def test_depth
    assert_equal(4, @book.navigation.depth)
  end
  
end