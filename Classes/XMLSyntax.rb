class XMLSyntax

  def self.sharedInstance
    @sharedInstance ||= self.new
  end
  
  def initialize
    @components = [
      { 
        :name       => "Tags",
        :type       => Syntax::TAG_TYPE, 
        :start      => "<", 
        :end        => ">", 
        :ignored    => "Strings", 
      },
      { 
        :name       => "Strings",
        :type       => Syntax::STRING_TYPE, 
        :start      => "\"", 
        :end        => "\"", 
        :escapeChar => "",
      },
      { 
        :name       => "Keywords", 
        :type       => Syntax::KEYWORD_TYPE, 
        :keywords   => ["&lt;", "&gt;", "&amp;", "&auml;", "&uuml;", "&ouml;"],
      },
      { 
        :name       => "Comments",
        :type       => Syntax::BLOCK_COMMENT_TYPE, 
        :start      => "<!--",
        :end        => "-->", 
      }
    ]
  end


  def each_component
    @components.each {|component| yield component}
  end
  
end