class String
  def sanitize
    self.strip.gsub(%r{[/"*:<>\?\\]}, '_')
  end
end

class NSCFString
  def sanitize
    self.strip.gsub(%r{[/"*:<>\?\\]}, '_')
  end
end
