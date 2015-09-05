#####################################################################
### this is the main program which gathers and outputs the completion
#####################################################################

require 'yaml' 

require_relative 'universal-utils.rb'
require_relative 'tokenize.rb'

include UniversalUtils


class String
  def tokenize
      a = Assembly.new self
      a.parse
  end
end

TrailCrumb = Struct.new(:completer, :node, :consumed)

class AbstractCompleter
  def initialize(choiceTree)
    @tree = choiceTree
  end

  def deriveChoices(choice, token)
    [choice]
  end

  # this method is used for long completions when tab is hit twice and multiple possible continuations are shown -- in this case it's nicer to display just the continuation rather than the entire full form choice
  # for example if you've typed "/usr/bin/m" and the possible continuations are ["/usr/bin/mysql", "/usr/bin/mongodb"] then on screen its nicer to just show ["mysql", "mongodb"]
  def abbreviate(rawChoice, choice, token)
    choice
  end

  def rawChoiceConsumesToken?(choice, token)
    expansion = deriveChoices(choice, token)
    if expansion.nil?
        log "expansion was nil using choice '#{choice}' and token '#{token}'"
    end
    expansion.each {|exp| 
        if ! token.nil?
            remainder = derivedChoiceConsumesToken?(exp, token)
            if ! remainder.nil?
                log "- #{exp} consumed from #{token} with remainder '#{remainder}'"
                return remainder
            end
        end
    }
    #log "'#{token}' was not consumed in #{expansion}"
    return nil
  end

  # this method is for consuming the existing tokens to the left of the current token
  def derivedChoiceConsumesToken?(derivedChoice, token)
    if token.nil?
        return nil
    end
    if token.start_with? derivedChoice
        tt = token.dup
        tt.slice! derivedChoice
        return tt
    else
        return nil
    end
  end

  # this method is for filtering matching choices based on the current incomplete token 
  # how does it differ from the derivedChoiceConsumesToken? method?
  # if choice is "red" and token is "r", then this method will return true, indicating that "red" is indeed a potential completion of "r"
  # the derivedChoiceConsumesToken? method on the other hand would return nil (ie false) because "red" cannot consume the token "r"
  def isChoicePotentialCompletion(derivedChoice, token)
    if token.nil?
        return true
    end
    derivedChoice.start_with? token
  end

  def self.isMyType(choice)
    self.class.name == self.parseTypeName(choice) 
  end

  def self.parseTypeName(rawChoice)
    if (! rawChoice.nil?) && (match = rawChoice.match(/^<([A-Z].*)>(.*)\s*$/i))
        answer = "#{match.captures[0]}Completer"
        log "#{rawChoice} is of type #{answer}"
        return answer
    else
        answer = StaticCompleter.name
        log "#{rawChoice} defaulted to type #{answer}"
        return answer
    end
  end

  # this returns the "data" of a choice -- for a normal static choice its the choice itself, but for a dynamic choice it's everything after the <>
  # so if the choice node is "fruit " this will return "fruit "
  # but if the choice node is "<MyThing>123 " then this returns "123"
  def self.content(rawChoice)
    if match = rawChoice.match(/^<([A-Z].*)>(.*)\s*$/i)
        return match.captures[1]
    else
        return rawChoice 
    end
  end

  def self.isMultiPart(choice)
      ! (choice =~ /\s$/)
  end

end

class StaticCompleter < AbstractCompleter
end

class DynamicCompleter < AbstractCompleter
end


class ChoiceTree
  attr_accessor :currentNode

  def initialize(configfile)
    @conf = YAML::load_file(configfile) 
    @conf.freeze
    @currentNode = @conf
    @completerCache = {}
    @consumptionTrail = []
  end

  def completerFactory(classname)
    answer = @completerCache[classname]
    if answer.nil?
        comp = completerClassFromString(classname)
        answer = comp.new self
        @completerCache[classname] = answer
    end
 
    answer
  end

  def categorizeChoices
    answer = [[],[]]
    @currentNode.keys.each{|k| 
        if DynamicCompleter.isMyType k
            answer[1].push k
        else
            answer[0].push k
        end
    } 
    return answer
  end

  # returns nil when not consumed, otherwise returns a string indicating what remained after consumption (will typically be an empty string, indicating that the token was fully consumed)
  # TODO: consider just always returning what remains, so instead of nil you'd return the full token to indicate non-consumption
  # purpose: every time you hit tab to invoke auto-completion, this ruby script is invoked from scratch, so this program essentially must operate statelessly.  Thus each time you must walk through the yaml completion tree from the beginning to re-figure out where in the tree you currently are.  This method is used as part of that tree navigation, so basically we start from root node and then recursively look for subnodes that can consume our token stack.  Once we cant consume any more then we've reached the current node and we then switch over to the matchingCandidates method to suggest to the user potential continuations from here 
  def consume?(token)
    log "trying to consume '#{token}'"
   
    if @currentNode.nil? 
        log "failed to fully consume '#{token}' from nil location reached via #{@consumptionTrail} "
        return nil
    end

    if @currentNode.length > 0
        # for efficiency, first handle the quick n easy static cases
        simpleC, dynamicC = categorizeChoices

        remainder = consumeChoices?(simpleC, token)
        return remainder if ! remainder.nil?

        remainder = consumeChoices?(dynamicC, token)
        return remainder if ! remainder.nil?
    end    
    log "failed to consume '#{token}' from location "
    log @currentNode.keys
    return nil
  end

  def consumeChoices?(choices, token)
    choices.each {|k|
        comp = completer k
        remainder = comp.rawChoiceConsumesToken?(comp.class.content(k), token)
        if ! remainder.nil?
            log "was at #{@currentNode.keys}"
            log "trying to move to #{k}"
            @currentNode = @currentNode[k]
            log "about to truncate '#{remainder}' from the end of '#{token}'"
            cIndex = [(token.length - remainder.length - 1), 0].max
            consumed = token[0..cIndex]
            @consumptionTrail.push TrailCrumb.new(comp, @currentNode, consumed)
            if ! @currentNode.nil?
                log "now at #{@currentNode.keys}"
            else
                log "now at the end of the road"
            end
            return remainder
        end
    }
    return nil
  end

  # only relevant for multi-part completions, eg:
  # color: 
  #     =green:
  #     =blue:
  # here when completing =green or =blue we want to know that this completion is really a continuation of color
  # so this method would return "color" in this case
  def completionPrefix()
    index = @consumptionTrail.length() -1
    answer = '' 
    loop do 
       break if index < 0 
       node = @consumptionTrail[index]
       if ! node.completer.kind_of?(StaticCompleter)
            log "parent was not StaticCompleter #{node.completer}"
            break
       end
       if ! AbstractCompleter.isMultiPart(node.consumed) 
            log "parent was not multi-part: #{node.consumed}"
            break
       end
       log "gathering from parent #{node.consumed}"
       answer.insert(0, node.consumed)
       index -= 1 
    end 
    return answer
  end

  # this is used to generate potential continuations for the text you've typed so far
  def matchingCandidates(token)
    candidates(@currentNode, token)
  end

  def candidates(node, token)
    answer = []
    abbrevAnswer = []
    if node.kind_of?(Hash) && ! node.keys.nil?
        
        node.keys.each {|candidate|
            compltr = completer candidate
            nodeContent = compltr.class.content(candidate)
            log "deriving all choices for token '#{token}' having node content #{nodeContent}"
            addCandidates = compltr.deriveChoices(nodeContent, token)

            log "about to select matches for '#{token}' from #{addCandidates}"
            addCandidates.select! {|c|
               compltr.isChoicePotentialCompletion(c, token)
            }
            answer.concat addCandidates

            #now that we've generated the matching candidates, lets also create abbreviations for them
            addCandidates.each{|c|
                abbr = compltr.abbreviate(nodeContent, c, token)
                if ! abbr.nil?
                    abbrevAnswer.push abbr
                end
            }
        }
    end
    log "derived choices to #{answer}"

    # when there are multiple continuations, we prefer to show them abbreviated when possible
    # but theres a special case when all of the continuation choices share any common prefix then bash immediately prints the common prefix 
    # thus in that case we need to show the full form so that this behavior does not wipe out what we've typed so far
    # (in other words, we must accept that this behavior will occur so we therefore tack on what's been typed already to each choice so that it gets preserved)
    if answer.length > 1 && ! shareACommonPrefix?(abbrevAnswer)
        answer = abbrevAnswer
        log "abbreviated to #{answer}"
    else
        prefix = completionPrefix()
        if prefix.length > 0
            answer.map!{|c|
                "#{prefix}#{c}"
            }
        end
        log "special case: could not abbreviate"
    end
    return answer

  end

  def shareACommonPrefix?(arr)
    if arr.nil? || arr.length < 1
        return false
    end

    firstLetter =  nil
    arr.each {|s|
        if firstLetter.nil?
            firstLetter = s[0]
        else
            if firstLetter != s[0]
                return false
            end
        end
    }
    return true
  end

  # fetches an appropriate Completer subclass to interpret the given choice node
  def completer(choice)
    if choice.nil?
      completerFactory(StaticCompleter.name)
    else    
      comp = completerFactory( AbstractCompleter.parseTypeName choice )
      log "using ruby class #{comp.to_s}"
      comp
    end
  end

  def rollback()
    if @consumptionTrail.length < 1
        return 
    end

    log "rolling back from #{@currentNode}"
    @consumptionTrail.pop
    @currentNode = @consumptionTrail[-1].node
    log "rolled back to #{@currentNode}"
  end

end

class AutoCompleter
  def initialize(configfile, rawinput)
    log "parsing rawinput #{rawinput}"
    @conf = ChoiceTree.new(configfile)
    if rawinput.nil? || rawinput.length <=1
        rawinput = ''
    end
    @rawinput = rawinput
    @input = rawinput.tokenize.map! {|i| "#{i} "}
    #@input = rawinput.split.map! {|i| "#{i} "}

    ### strip space from @input if needed to match @rawinput
    if @rawinput[-1] != " " 
       @input[-1].strip!
    end
    @tokenIndex = 0
  end

  # the main processing loop for the whole program
  def parse
    @input.reverse!
    loop do
       if @input.empty?
          break
       end
       t = @input.pop
       t.freeze
       remainder = @conf.consume?(t)
       if remainder.nil? 
           log "+ #{t} not consumed"
           return @conf.matchingCandidates(t)
       elsif remainder.strip.length > 0
            @input.push remainder
       end
    end
    return @conf.matchingCandidates(nil)
  end
   
end
