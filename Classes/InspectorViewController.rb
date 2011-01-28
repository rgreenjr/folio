class InspectorViewController < NSViewController

  attr_accessor :bookController, :textField, :attributesView, :emptyView

  def initWithBookController(bookController)
    initWithNibName("InspectorView", bundle:nil)
    @bookController = bookController
    self
  end
  
  def loadView
    super
    addView(@emptyView)
    showEmptyView
  end

  def displayObject(object)
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
  
  private
  
  def showEmptyView
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = true
    emptyView.hidden = false
  end
  
  def showPointView(point)
    pointViewController.point = point
    pointViewController.view.hidden = false
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = true
    emptyView.hidden = true
  end
  
  def showItemRefView(itemref)
    itemRefViewController.itemref = itemref
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = false
    itemViewController.view.hidden = true
    emptyView.hidden = true
  end
  
  def showItemView(item)
    itemViewController.item = item
    pointViewController.view.hidden = true
    itemRefViewController.view.hidden = true
    itemViewController.view.hidden = false
    emptyView.hidden = true
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
  
  def addView(view)
    view.hidden = true
    view.frame = @attributesView.frame
    @attributesView.addSubview(view)
  end

end