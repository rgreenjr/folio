require 'test/unit'

class BookTest < Test::Unit::TestCase
  
  def setup
    path = File.expand_path(File.dirname(__FILE__)) + "/../data/The Fall of the Roman Empire_ A New History of Rome and the Barbarians.epub"
    @book = Book.new(path)
  end
  
  def teardown
  end
  
  def test_title
    assert_equal("The Fall of the Roman Empire: A New History of Rome and the Barbarians", @book.metadata.title)
  end
  
  def test_depth
    assert_equal(4, @book.navigation.depth)
  end
  
end