####################
### this class executes its rawchoice in a bash shell and returns the results
### the variable $ASKBASH_TOKEN will be available in the shell
####################

class ExecCompleter < DynamicCompleter
  def deriveChoices(rawchoice, token)
    log "deriveChoices '#{token}'"
    cmd = "export ASKBASH_TOKEN=#{token}; #{rawchoice}"
    answer = runShellCommand(cmd)
    if ! rawchoice.nil? && ! answer.nil? && answer.length > 0 && rawchoice =~ /.*\s$/
        answer.map! {|a|
            "#{a} "
        }
    end
    answer
  end
end

