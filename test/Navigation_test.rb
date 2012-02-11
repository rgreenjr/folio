require 'test/unit'

class NavigationTest < Test::Unit::TestCase
  
  def setup
    url = NSURL.fileURLWithPath(File.expand_path(File.dirname(__FILE__)) + "/../data/The Fall of the Roman Empire.epub")
    @book = Book.alloc.init
    error = Pointer.new(:id)
    unless @book.readFromURL(url, ofType:"epub", error:error)
      puts error[0].localizedDescription
    end
  end
  
  def test_depth
    assert_equal(4, @book.container.package.navigation.depth)
  end
  
  def test_docAuthor
    assert_equal(nil, @book.container.package.navigation.docAuthor)
  end
  
  def test_root_point
    point = @book.container.package.navigation.root[0]
    assert_equal("The Fall of the Roman Empire", point.text)
    assert_equal("navPoint-1", point.id)
    assert_equal("Text/The_Fall_of_-e_Roman_Empire_split_001.html", point.src)
  end
  
  def test_nested_point
    point = @book.container.package.navigation.root[0][4][0][1]
    assert_equal("‘The Better Part of Humankind’", point.text)
    assert_equal("navPoint-9", point.id)
    assert_equal("Text/The_Fall_of_-e_Roman_Empire_split_008.html#heading_id_4", point.src)
  end

  # need to figure out way to get NSBundle to load files from here
  # def test_save
  #   @book.container.package.navigation.save("/Users/rgreen/Desktop")
  #   true
  # end
  
end
