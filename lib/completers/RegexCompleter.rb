#############
### matches by treating choice as a regex for the token.  if the regex accepts the token, then the token itself is returned as a choice
#############

class RegexCompleter < DynamicCompleter

  def deriveChoices(choice, token)
    if token.nil?
        []
    elsif match = token.match( /^(#{choice})$/)
        log "regex consumed #{choice} from #{token}"
        [token]
    else
        log "regex did not match #{choice} to #{token}"
        []
    end
  end

end


