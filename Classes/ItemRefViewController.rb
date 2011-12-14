class ItemRefViewController < NSViewController

  attr_accessor :item, :typePopup, :linearCheckBox

  def initWithBookController(bookController)
    initWithNibName("ItemRefView", bundle:nil)
    @bookController = bookController
    self
  end

  def loadView
    super
    Guide.types.each {|type| @typePopup.addItemWithTitle(type)}
  end

  def itemref=(itemref)
    @itemref = itemref
    updateView
  end
  
  def updateItemRef(sender)
    if sender == @typePopup
      changeType(@itemref, Guide.code_for(@typePopup.titleOfSelectedItem))
    else
      changeLinearity(@itemref, @linearCheckBox.state == NSOnState ? 'yes' : 'no')
    end
  end
  
  def changeType(itemref, value)
    return if itemref.type == value
    undoManager.prepareWithInvocationTarget(self).changeType(itemref, itemref.type)
    undoManager.actionName = "Change ItemRef Type"
    itemref.type = value
    updateView
  end

  def changeLinearity(itemref, value)
    return if itemref.linear == value
    undoManager.prepareWithInvocationTarget(self).changeLinearity(itemref, itemref.linear)
    undoManager.actionName = "Change ItemRef Linearity"
    itemref.linear = value
    updateView
  end

  private

  def updateView
    if @itemref
      guideType = Guide.name_for(@itemref.type) || "None"
      @typePopup.selectItemWithTitle(guideType)
      @linearCheckBox.state = @itemref.linear? ? NSOnState : NSOffState
      @bookController.selectionViewController.reloadItem(@itemref)
    end
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end