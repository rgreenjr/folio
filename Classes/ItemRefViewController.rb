class ItemRefViewController < NSViewController

  attr_accessor :item
  attr_accessor :typePopup
  attr_accessor :linearCheckBox

  def initWithBookController(controller)
    initWithNibName("ItemRefView", bundle:nil)
    @bookController = controller
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
      changeReferenceType(@itemref, Guide.type_for(@typePopup.titleOfSelectedItem))
    else
      changeLinearity(@itemref, @linearCheckBox.state == NSOnState ? 'yes' : 'no')
    end
  end
  
  def changeReferenceType(itemref, value)
    return if itemref.item.referenceType == value
    undoManager.prepareWithInvocationTarget(self).changeReferenceType(itemref, itemref.item.referenceType)
    undoManager.actionName = "Change ItemRef Type"
    itemref.item.referenceType = value
    itemref.item.referenceTitle = Guide.title_for(value)
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
      title = Guide.title_for(@itemref.item.referenceType) || "None"
      @typePopup.selectItemWithTitle(title)
      @linearCheckBox.state = @itemref.linear? ? NSOnState : NSOffState
      @bookController.selectionViewController.reloadItem(@itemref)
    end
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end