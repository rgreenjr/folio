class XMLSyntax < Syntax

  def self.sharedInstance
    @sharedInstance ||= self.new
  end

  def initialize
    self.tags = { 
      :name   => "Tags",
      :type   => Syntax::TAG_TYPE,
      :regex  => /<(?:"[^"]*"['"]*|'[^']*'['"]*|[^'">])+>/,
      :ignore => "Strings"
    }

    self.strings = { 
      :name   => "Strings",
      :type   => Syntax::STRING_TYPE,
      :regex  => /"(?:[^"\\]|\\.)*"/
    }

    self.keywords = {
      :name   => "Keywords",
      :type   => Syntax::KEYWORD_TYPE,
      :regex  => /&([a-zA-Z]+|#\d+|#x[a-fA-F0-9]+);/
    }

    self.blockComments = { 
      :name   => "BlockComments",
      :type   => Syntax::BLOCK_COMMENT_TYPE, 
      :regex  => /<!--.*?-->/m 
    }      
  end

end