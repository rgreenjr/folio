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
      changeLinear(@itemref, @linearCheckBox.state == NSOnState ? 'yes' : 'no')
    end
  end
  
  def changeType(itemref, value)
    return if itemref.type == value
    undoManager.prepareWithInvocationTarget(self).changeType(itemref, itemref.type)
    undoManager.actionName = "Change Type"
    itemref.type = value
    updateView
    @bookController.selectionViewController.reloadItem(itemref)
  end

  def changeLinear(itemref, value)
    return if itemref.linear == value
    undoManager.prepareWithInvocationTarget(self).changeLinear(itemref, itemref.linear)
    undoManager.actionName = "Change Linear"
    itemref.linear = value
    updateView
    @bookController.selectionViewController.reloadItem(itemref)
  end

  private

  def updateView
    if @itemref
      @typePopup.selectItemWithTitle(Guide.name_for(@itemref.type))
      @linearCheckBox.state = @itemref.linear? ? NSOnState : NSOffState
    end
  end

  def undoManager
    @undoManager ||= @bookController.window.undoManager
  end

end