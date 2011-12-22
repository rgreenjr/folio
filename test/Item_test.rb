require 'test/unit'

class ItemTest < Test::Unit::TestCase
  
  def setup
    @root = Item.new(nil, "cover.jpg")
  end
  
  def test_inititalize_root
    assert_equal(nil, @root.parent)
    assert_equal("cover.jpg", @root.name)
    assert_not_nil(@root.id)
    assert_equal(Media::JPG, @root.mediaType)
    assert_equal(false, @root.expanded?)
    assert_equal(0, @root.issues.size)
    assert_equal(false, @root.directory?)
  end

  def test_inititalize_child
    item = Item.new(@root, "cover.jpg")
    @root << item
    assert_equal(@root, item.parent)
    assert_equal(true, item.hasParent?)
    assert_equal("cover.jpg", item.name)
    assert_not_nil(item.id)
    assert_equal(Media::JPG, item.mediaType)
    assert_equal(false, item.expanded?)
    assert_equal(0, item.issues.size)
    assert_equal(false, item.directory?)
    assert_equal(1, item.parent.size)
  end

end
