class UUID

  def self.create
    field(8) + '-' + field(4) + '-' + field(4) + '-' + field(4) + '-' + field(12)
  end
  
  def self.field(length)
    (0...length).map{ rand(16).to_s(16) }.join
  end

end
