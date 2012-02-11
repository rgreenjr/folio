module REXML
  class ParseException < RuntimeError
    def explain
      "#{exception.continued_exception} on line: #{line}"
    end
  end
end
