class Container

  def to_xml
      FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{@tmp}/META-INF/container.xml")
  end
  
end