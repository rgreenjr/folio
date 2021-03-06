class InspectorViewController < NSViewController

  attr_reader   :bookController
  attr_reader   :inspectedObject
  attr_accessor :attributesView
  attr_accessor :emptyView
  attr_accessor :titleTextField
  
  def initWithBookController(controller)
    initWithNibName("InspectorView", bundle:nil)
    @bookController = controller
    self
  end
  
  def loadView
    super
    addView(@emptyView)
    showEmptyView
  end

  def inspectedObject=(object)
    @inspectedObject = object
    toggleView(@inspectedObject) if visible?
  end
  
  def showView
    return false if view.frame.origin.y > 0
    view.hidden = false
    view.frameOrigin = [0, -viewHeight]
    view.animator.frameOrigin = [0, 0]
    toggleView(@inspectedObject)
    true
  end
  
  def hideView
    return false if view.frame.origin.y < 0
    view.animator.frameOrigin = [0, -viewHeight]
    view.animator.hidden = true
    true
  end
  
  def viewHeight
    view.frame.size.height
  end
  
  def visible?
    view && !view.hidden?
  end
  
  def pointViewController
    unless @pointViewController
      @pointViewController ||= PointViewController.alloc.initWithBookController(@bookController)
      addView(@pointViewController.view)
    end
    @pointViewController
  end

  def itemRefViewController
    unless @itemRefViewController
      @itemRefViewController ||= ItemRefViewController.alloc.initWithBookController(@bookController)
      addView(@itemRefViewController.view)
    end
    @itemRefViewController
  end
  
  def itemViewController
    unless @itemViewController
      @itemViewController ||= ItemViewController.alloc.initWithBookController(@bookController)
      addView(@itemViewController.view)
    end
    @itemViewController
  end
  
  private
  
  def toggleView(object)
    if object == nil 
      showEmptyView
    elsif object.class == Point
      showPointView(object)
    elsif object.class == ItemRef
      showItemRefView(object)
    elsif object.class == Item
      showItemView(object)
    end
  end
  
  def showEmptyView
    @titleTextField.stringValue = "Properties Inspector"
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = true
    emptyView.hidden = false
  end
  
  def showPointView(point)
    @titleTextField.stringValue = "Point Inspector"
    pointViewController.point = point
    pointViewController.view.hidden = false
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = true
    emptyView.hidden = true
  end
  
  def showItemRefView(itemref)
    @titleTextField.stringValue = "ItemRef Inspector"
    itemRefViewController.itemref = itemref
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = false
    itemViewController.view.hidden = true
    emptyView.hidden = true
  end
  
  def showItemView(item)
    @titleTextField.stringValue = "Item Inspector"
    itemViewController.item = item
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = false
    emptyView.hidden = true
  end
  
  def addView(view)
    view.hidden = true
    view.frame = @attributesView.frame
    @attributesView.addSubview(view)
  end

end