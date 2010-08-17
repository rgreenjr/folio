class Container

  attr_reader :root, :fullpath, :absolutepath

  def initialize(root)
    path = "#{root}/META-INF/container.xml"
    raise "the META-INF/container.xml file is missing" unless File.exists?(path)
    @fullpath = REXML::Document.new(File.read(path)).root.elements["rootfiles/rootfile"].attributes["full-path"]
    @absolutepath = "#{root}/#{@fullpath}"
    @root = File.dirname(@fullpath)
  end
  
  def save(directory)
    FileUtils.cp(NSBundle.mainBundle.pathForResource("container", ofType:"xml"), "#{directory}/META-INF/container.xml")
  end

end