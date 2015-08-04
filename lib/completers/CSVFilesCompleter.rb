###################
### this completer is for completing a local file path
###################
require_relative 'FileCompleter.rb'


class CSVFilesCompleter < DynamicCompleter

  def initialize(choiceTree)
    @tree = choiceTree
    @fc = FileCompleter.new(choiceTree)
  end

  def deriveChoices(rawchoice, token)
    if ! token.nil? && token.length > 0 && token[-1] == " "
        return [ token ]
    end
    toks = token.split(/,/)
    if(toks.size > 1)
        prefix = toks[0..-2].join ',' 
        prefix += ','
        tok = toks[-1]
        answer = @fc.deriveChoices(rawchoice, tok)
        if(!answer.nil?)
            answer.map! {|a|
               prefix + a 
            }
        end
    else
        answer = @fc.deriveChoices(rawchoice, token)
    end
    
    return answer
  end
    
  def abbreviate(choice, token)
    toks = choice.split(/,/)
    tok = toks[-1]
    File.basename(tok.strip)
  end

end


