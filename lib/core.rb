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

  def abbreviate(choice, token)
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

  def self.parseTypeName(rawchoice)
    if (! rawchoice.nil?) && (match = rawchoice.match(/^<([A-Z].*)>(.*)\s*$/i))
        answer = "#{match.captures[0]}Completer"
        log "#{rawchoice} is of type #{answer}"
        return answer
    else
        answer = StaticCompleter.name
        log "#{rawchoice} defaulted to type #{answer}"
        return answer
    end
  end

  def self.content(rawchoice)
    if match = rawchoice.match(/^<([A-Z].*)>(.*)\s*$/i)
        return match.captures[1]
    else
        return rawchoice 
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

  def matchingCandidates(token)
    candidates(@currentNode, token)
  end

  def candidates(node, token)
    answer = []
    abbrevAnswer = []
    if node.kind_of?(Hash) && ! node.keys.nil?
        
        node.keys.each {|c|
            comp = completer c
            log "deriveing all choices for token '#{token}'"
            addition = comp.deriveChoices(comp.class.content(c), token)

            log "about to select matches for '#{token}' from #{addition}"
            addition.select! {|c|
               comp.isChoicePotentialCompletion(c, token)
            }
            answer.concat addition

            addition.each{|c|
                abb = comp.abbreviate(c, token)
                if abb.nil?
                    next
                else
                    abbrevAnswer.push abb
                end
            }
        }
    end
    log "derived choices to #{answer}"

    # theres a special case when all of the answers share any common prefix then bash immediately prints it, thus in this case we need to show the full form
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
