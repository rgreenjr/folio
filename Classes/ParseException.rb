module REXML
  class ParseException < RuntimeError
    def explain
      "\n\n#{exception.continued_exception} on line: #{line}"
    end
  end
end
