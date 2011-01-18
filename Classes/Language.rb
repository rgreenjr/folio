# ISO 639 Language Codes

class Language

  CODES = {}
  NAMES = {}
  DATA  = [
    ["aa", "Afar"],
    ["ab", "Abkhazian"],
    ["af", "Afrikaans"],
    ["am", "Amharic"],
    ["ar", "Arabic"],
    ["as", "Assamese"],
    ["ay", "Aymara"],
    ["az", "Azerbaijani"],
    ["ba", "Bashkir"],
    ["be", "Byelorussian"],
    ["bg", "Bulgarian"],
    ["bh", "Bihari"],
    ["bi", "Bislama"],
    ["bn", "Bengali"],
    ["bo", "Tibetan"],
    ["br", "Breton"],
    ["ca", "Catalan"],
    ["co", "Corsican"],
    ["cs", "Czech"],
    ["cy", "Welch"],
    ["da", "Danish"],
    ["de", "German"],
    ["dz", "Bhutani"],
    ["el", "Greek"],
    ["en", "English"],
    ["eo", "Esperanto"],
    ["es", "Spanish"],
    ["et", "Estonian"],
    ["eu", "Basque"],
    ["fa", "Persian"],
    ["fi", "Finnish"],
    ["fj", "Fiji"],
    ["fo", "Faeroese"],
    ["fr", "French"],
    ["fy", "Frisian"],
    ["ga", "Irish"],
    ["gd", "Scots Gaelic"],
    ["gl", "Galician"],
    ["gn", "Guarani"],
    ["gu", "Gujarati"],
    ["ha", "Hausa"],
    ["hi", "Hindi"],
    ["he", "Hebrew"],
    ["hr", "Croatian"],
    ["hu", "Hungarian"],
    ["hy", "Armenian"],
    ["ia", "Interlingua"],
    ["id", "Indonesian"],
    ["ie", "Interlingue"],
    ["ik", "Inupiak"],
    ["is", "Icelandic"],
    ["it", "Italian"],
    ["iu", "Inuktitut (Eskimo)"],
    ["ja", "Japanese"],
    ["jw", "Javanese"],
    ["ka", "Georgian"],
    ["kk", "Kazakh"],
    ["kl", "Greenlandic"],
    ["km", "Cambodian"],
    ["kn", "Kannada"],
    ["ko", "Korean"],
    ["ks", "Kashmiri"],
    ["ku", "Kurdish"],
    ["ky", "Kirghiz"],
    ["la", "Latin"],
    ["ln", "Lingala"],
    ["lo", "Laothian"],
    ["lt", "Lithuanian"],
    ["lv", "Latvian, Lettish"],
    ["mg", "Malagasy"],
    ["mi", "Maori"],
    ["mk", "Macedonian"],
    ["ml", "Malayalam"],
    ["mn", "Mongolian"],
    ["mo", "Moldavian"],
    ["mr", "Marathi"],
    ["ms", "Malay"],
    ["mt", "Maltese"],
    ["my", "Burmese"],
    ["na", "Nauru"],
    ["ne", "Nepali"],
    ["nl", "Dutch"],
    ["no", "Norwegian"],
    ["oc", "Occitan"],
    ["or", "Oriya"],
    ["pa", "Punjabi"],
    ["pl", "Polish"],
    ["ps", "Pashto, Pushto"],
    ["pt", "Portuguese"],
    ["qu", "Quechua"],
    ["rm", "Rhaeto-Romance"],
    ["rn", "Kirundi"],
    ["ro", "Romanian"],
    ["ru", "Russian"],
    ["rw", "Kinyarwanda"],
    ["sa", "Sanskrit"],
    ["sd", "Sindhi"],
    ["sg", "Sangro"],
    ["sh", "Serbo-Croatian"],
    ["si", "Singhalese"],
    ["sk", "Slovak"],
    ["sl", "Slovenian"],
    ["sm", "Samoan"],
    ["sn", "Shona"],
    ["so", "Somali"],
    ["sq", "Albanian"],
    ["sr", "Serbian"],
    ["ss", "Siswati"],
    ["st", "Sesotho"],
    ["su", "Sudanese"],
    ["sv", "Swedish"],
    ["sw", "Swahili"],
    ["ta", "Tamil"],
    ["te", "Tegulu"],
    ["tg", "Tajik"],
    ["th", "Thai"],
    ["ti", "Tigrinya"],
    ["tk", "Turkmen"],
    ["tl", "Tagalog"],
    ["tn", "Setswana"],
    ["to", "Tonga"],
    ["tr", "Turkish"],
    ["ts", "Tsonga"],
    ["tt", "Tatar"],
    ["tw", "Twi"],
    ["ug", "Uigur"],
    ["uk", "Ukrainian"],
    ["ur", "Urdu"],
    ["uz", "Uzbek"],
    ["vi", "Vietnamese"],
    ["vo", "Volapuk"],
    ["wo", "Wolof"],
    ["xh", "Xhosa"],
    ["yi", "Yiddish"],
    ["yo", "Yoruba"],
    ["za", "Zhuang"],
    ["zh", "Chinese"],
    ["zu", "Zulu"]
  ]

  DATA.each do |code, name|
    CODES[code] = name
    NAMES[name] = code
  end
  
  def self.code_for(name)
    NAMES[name]
  end

  def self.name_for(code)
    CODES[code]
  end
  
  def self.names
    @names ||= NAMES.keys.sort
  end

end