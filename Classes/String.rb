module StringEnhancements

  def sanitize
    strip.gsub(%r{[/"*:<>\?\\]}, '_')
  end

  def titleize
    gsub(/\b(\w*)/) { $1.downcase.capitalize }
  end

  def downcasePrepositions
    %w{a and as at by for from of in on or the to with}.inject(self) do |string, word| 
      string.gsub(/(\w) #{word} /i) { "#{$1} #{word.downcase} " }
    end
  end
  
  def escapeHTML
     CGI.escapeHTML(self)
  end

  def urlEscape
    self.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
  end

  def pluralize(count, plural=nil)
    number = count.to_i
    if number == 1
      "#{number} #{self}"
    else
      plural ? "#{number} #{plural}" : "#{number} #{self}s"
    end
  end

end

class String
  include StringEnhancements
end

class NSCFString
  include StringEnhancements
end

class NSMutableString
  include StringEnhancements
end
