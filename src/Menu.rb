class NSMenu
  
  def addAction(title, action, target, keyEquivalent="")
    menuItem = NSMenuItem.alloc.initWithTitle(title, action:action, keyEquivalent:keyEquivalent)
    menuItem.target = target    
    addItem(menuItem)
  end
  
  def addSeparator
    addItem(NSMenuItem.separatorItem)
  end
  
end