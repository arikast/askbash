###################
### this completer is for completing a local file path
###################

class FileCompleter < DynamicCompleter
  def deriveChoices(rawChoice, token)
    if ! token.nil? && token.length > 0 && token[-1] == " "
        return [ token ]
    end
    
    tok = if token.nil? then "" else token.strip end
    log "about to glob '#{tok}'"
    answer = Dir.glob("#{tok}*") 
    answer.map! {|a| 
        if File.directory?(a) 
            "#{a}/"
        else
            "#{a} "
        end
    }
    if answer.length < 1 && File.exist?(tok)
        answer = [token] 
    end
    
    answer.map! {|a|
        a.gsub(/([^\\])(\s)(?!$)/, '\\1' + '\\\\' + '\\2')
    }
    log "glob returned #{answer}"
    return answer
  end

  def abbreviate(rawChoice, choice, token)
    File.basename(choice.strip)
  end

end


