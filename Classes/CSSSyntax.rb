class CSSSyntax
  
  def self.sharedInstance
    @syntax ||= [
      { 
        :name       => "Tags",
        :type       => Syntax::TAG_TYPE,
        :start      => "{", 
        :end        => "} ", 
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
        :keywords   => ["background:", "background-attachment:", "background-color:", "background-image:", "background-position:", 
                        "background-repeat:", "border:", "border-bottom:", "border-bottom-color:", "border-bottom-style:", "border-bottom-width:", 
                        "border-color:", "border-left:", "border-left-color:", "border-left-style:", "border-left-width:", "border-right:", 
                        "border-right-color:", "border-right-style:", "border-right-width:", "border-style:", "border-top:", "border-top-color:", 
                        "border-top-style:", "border-top-width:", "border-width:", "clear:", "cursor:", "display:", "float:", "position:", 
                        "visibility:", "height:", "line-height:", "max-height:", "min-height:", "min-width:", "width:", "font:", "font-family:", 
                        "font-size:", "font-size-adjust:", "font-strech:", "font-style:", "font-variant:", "font-weight:", "content:", 
                        "counter-increment:", "counter-reset:", "quotes:", "list-style:", "list-style-image:", "list-style-position:", 
                        "list-style-type:", "marker-offset:", "margin:", "margin-bottom:", "margin-left:", "margin-right:", "margin-top:", 
                        "outline:", "outline-color:", "outline-style:", "outline-width:", "padding:", "padding-bottom:", "padding-left:", 
                        "padding-right:", "padding-top:", "bottom:", "clip:", "left:", "overflow:", "right:", "top:", "vertical-align:", 
                        "z-index:", "border-collapse:", "border-spacing:", "caption-side:", "empty-cells:", "table-layout:", "color:", 
                        "direction:", "letter-spacing:", "text-align:", "text-decoration:", "text-indent:", "text-shadow:", "text-transform:", 
                        "unicode-bidi:", "white-space:"],
      },
      { 
        :name       => "Comments",
        :type       => Syntax::BLOCK_COMMENT_TYPE,
        :start      => "/*",
        :end        => "*/", 
      }
    ]
  end
  
end