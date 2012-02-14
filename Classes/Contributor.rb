class Contributor

  CODES = {}
  NAMES = {}
  DATA = [
    ["arr", "Arranger"],
    ["art", "Artist"],
    ["asn", "Associated name"],
    ["aut", "Author"],
    ["aqt", "Author in Quotations or Text Extracts"],
    ["aft", "Author of Afterword, Colophon, etc."],
    ["aui", "Author of Introduction, etc."],
    ["ant", "Bibliographic Antecedent"],
    ["bkp", "Book Producer"],
    ["clb", "Collaborator"],
    ["cmm", "Commentator"],
    ["dsr", "Designer"],
    ["edt", "Editor"],
    ["ill", "Illustrator"],
    ["lyr", "Lyricist"],
    ["mdc", "Metadata contact"],
    ["mus", "Musician"],
    ["nrt", "Narrator"],
    ["oth", "Other"],
    ["pht", "Photographer"],
    ["prt", "Printer"],
    ["red", "Redactor"],
    ["rev", "Reviewer"],
    ["spn", "Sponsor"],
    ["ths", "Thesis Advisor"],
    ["trc", "Transcriber"],
    ["trl", "Translator"]
  ]

  DATA.each do |code, name|
    CODES[code] = name
    NAMES[name] = code
  end

  def self.codeForName(name)
    NAMES[name]
  end

  def self.nameForCode(code)
    CODES[code]
  end

  def self.names
    @names ||= NAMES.keys.sort
  end

end