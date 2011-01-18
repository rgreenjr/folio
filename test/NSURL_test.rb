require 'test/unit'

class NSURL_test < Test::Unit::TestCase
  
  def test_no_scheme
    assert_equal(false, NSURL.URLWithString("/Library/Support").remote?)
  end
  
  def test_file_scheme
    assert_equal(false, NSURL.URLWithString("file:///Applications/").remote?)
  end
  
  def test_http_scheme
    assert_equal(true, NSURL.URLWithString("http://www.foobar.com").remote?)
  end
  
end
