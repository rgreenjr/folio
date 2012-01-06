class XMLSyntax < Syntax

  def self.sharedInstance
    @sharedInstance ||= self.new
  end
  
  def initialize
      self.tags = { 
        :name       => "Tags",
        :type       => Syntax::TAG_TYPE, 
        :start      => "<", 
        :end        => ">", 
        :ignored    => "Strings", 
      }
      
      self.strings = { 
        :name       => "Strings",
        :type       => Syntax::STRING_TYPE, 
        :start      => "\"", 
        :end        => "\"", 
        :escapeChar => "",
      }
      
      self.keywords = {
        :name       => "Keywords", 
        :type       => Syntax::KEYWORD_TYPE, 
        :list       => ["&lt;", "&gt;", "&amp;", "&auml;", "&uuml;", "&ouml;"],
      }
      
      self.blockComments = { 
        :name       => "BlockComments",
        :type       => Syntax::BLOCK_COMMENT_TYPE, 
        :start      => "<!--",
        :end        => "-->", 
      }      
  end

end