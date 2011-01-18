require 'test/unit'

class MetadataTest < Test::Unit::TestCase
  
  def setup
    url = NSURL.fileURLWithPath(File.expand_path(File.dirname(__FILE__)) + "/../data/The Fall of the Roman Empire.epub")
    @book = Book.alloc.init
    error = Pointer.new(:id)
    unless @book.readFromURL(url, ofType:"epub", error:error)
      puts error[0].localizedDescription
    end
  end
  
  def test_title
    assert_equal("The Fall of the Roman Empire: A New History of Rome and the Barbarians", @book.metadata.title)
  end
  
  def test_description
    assert_equal("In this groundbreaking book, Peter Heather proposes the theory that Rome generated its own nemesis.", @book.metadata.description)
  end
  
  def test_language
    assert_equal("en", @book.metadata.language)
  end
  
  def test_identifier
    assert_equal("d4a01fde-c9cc-441c-86a5-156c9a765371", @book.metadata.identifier)
  end
  
  def test_creator
    assert_equal("Peter Heather", @book.metadata.creator)
  end
  
  def test_sortCreator
    assert_equal("Heather, Peter", @book.metadata.sortCreator)
  end
  
  def test_publisher
    assert_equal("Oxford University Press US", @book.metadata.publisher)
  end

end
