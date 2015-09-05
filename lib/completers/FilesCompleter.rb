###################
### this completer is for completing one or more local file paths separated by an arbitrary token separator
###################
require_relative 'FileCompleter.rb'


class FilesCompleter < DynamicCompleter

  def initialize(choiceTree)
    @tree = choiceTree
    @fc = FileCompleter.new(choiceTree)
  end

  def deriveChoices(rawChoice, token)
    if ! token.nil? && token.length > 0 && token[-1] == " "
        return [ token ]
    end
    toks = token.split(separator(rawChoice))
    if(toks.size > 1)
        prefix = toks[0..-2].join(separator(rawChoice))
        prefix += ','
        tok = toks[-1]
        answer = @fc.deriveChoices(rawChoice, tok)
        if(!answer.nil?)
            answer.map! {|a|
               prefix + a 
            }
        end
    else
        answer = @fc.deriveChoices(rawChoice, token)
    end
    
    return answer
  end
    
  def abbreviate(rawChoice, choice, token)
    toks = choice.split(separator(rawChoice))
    tok = toks[-1]
    File.basename(tok.strip)
  end

  def separator(rawChoice)
    if rawChoice.nil? || rawChoice.length == 0
        return ','
    else
        return rawChoice.strip
    end
  end

end


