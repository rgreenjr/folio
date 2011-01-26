class InspectorViewController < NSViewController

  attr_accessor :bookController

  def initWithBookController(bookController)
    initWithNibName("InspectorView", bundle:nil)
    @bookController = bookController
    self
  end

  def awakeFromNib
  end

end