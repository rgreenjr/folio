class String
  def sanitize
    strip.gsub(%r{[/"*:<>\?\\]}, '_')
  end
end

class NSCFString
  def sanitize
    strip.gsub(%r{[/"*:<>\?\\]}, '_')
  end
end
