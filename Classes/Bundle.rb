class Bundle

  def self.path(name, type)
    NSBundle.mainBundle.pathForResource(name, ofType:type)
  end

  def self.read(name, type)
    File.read(self.path(name, type))
  end

  def self.template(name)
    self.read(name, 'erb')
  end

end