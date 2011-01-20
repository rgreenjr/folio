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
end

class String
  include StringEnhancements
end

class NSCFString
  include StringEnhancements
end