require 'yaml' 

class Assembly
    
    attr_accessor :parsers, :text, :result

    def initialize(text)
        @text = text
        @parsers = []
        @result = []
    end

    def makeView
        AssemblyView.new self
    end

    def pushTerm(term)
        if term.nil? || term =~ /^\s*$/
            return
        end
        @result.push term
    end
    
    def parse
        graph = TokenStateGraph.new
        graph.parse self

        return result
    end
end

class AssemblyView

    attr_accessor :consumedIndex, :assembly

    def initialize(assembly, consumedIndex=0, currentWordStart=consumedIndex)
        @assembly = assembly
        @consumedIndex = consumedIndex
        @currentWordStart = currentWordStart
    end

    def consume(numOfChars)
        @consumedIndex += numOfChars
    end

    def unconsume(numOfChars)
        @consumedIndex -= numOfChars
    end

    def consumable(idx=@consumedIndex)
        @assembly.text.slice(idx, @assembly.text.length - idx)
    end

    def isFinished(idx=@consumedIndex)
        idx >= @assembly.text.length
    end

    def consumed(idx=@consumedIndex)
        @assembly.text.slice(0, idx)
    end

    def peek(idx=0)
        if consumable.nil? || consumable.length == 0
            return ""
        end
        answer = consumable[idx]
        if consumable.length > 1 && answer == '\\'
            answer += consumable[idx + 1]
            log "escaped char found: '#{answer}'"
        end
            
        return answer
    end

    def lookAhead(idx)
        return consumable.slice(0,idx)
    end
    
    def popChar
        answer = peek
        consume answer.length 
    end

    def peekWord
        @assembly.text.slice(@currentWordStart, @consumedIndex - @currentWordStart)
    end

    def popWord
        answer = peekWord
        log "popping word length #{answer.length}: #{answer}"
        @currentWordStart = @consumedIndex
        return answer
    end

    def copy
        AssemblyView.new(@assembly, @consumedIndex, @currentWordStart)
    end
end

class TokenStateGraph
    
    def initialize
        @default = nil

        #note that a simple '.*' regex is not adequate because we need to allow for presence of \'
        @apostrophe = PairedToken.new("'")

        #note that a simple ".*" regex is not adequate because we need to allow for presence of \"
        @quote      = PairedToken.new('"') 

        @space      = RegexToken.new('\s+')
        
        #note that this needs to go char by char to allow for things like: wow' this is 'interesting
        @word       = OneAtATimeToken.new('\S')

        #@default.allowedTransitions = [@apostrope, @quote, @space, @word]
        #@apostrophe.allowedTransitions = []
        #@quote.allowedTransitions = []
        #@space.allowedTransitions =  @default.allowedTransitions
        #@word.allowedTransitions =  @default.allowedTransitions

        #@stateStack = []
        #@stateStack.push @default
        
        @current = @default
    end

    def parse(assembly)
        log "starting scanner/tokenize of #{assembly.text}"
        view = assembly.makeView
                 
        loop do
            if view.isFinished
                assembly.pushTerm(view.popWord)
                break
            end
            
            if (howMany = @apostrophe.accepts(view)) > 0
                view.consume howMany 
                @current = @apostrophe 
                next
            elsif(howMany = @quote.accepts(view)) > 0 
                view.consume howMany 
                @current = @quote 
                next
            elsif (howMany = @space.accepts(view)) > 0
                if @current != @space
                    assembly.pushTerm(view.popWord) 
                end
                view.consume howMany 
                #throw away the empty space word
                view.popWord
                @current = @space 
                next
            elsif (howMany = @word.accepts(view)) > 0
                view.consume howMany 
                @current = @word 
                next
            end
            log("unable to parse further, got as far as #{view.consumed}<<<HERE>>>#{view.consumable}")
            break
        end
        log "finished scanner/tokenize phase"
        log "----------------------------"
    end
end

class GenericToken
    attr_accessor :allowedTransitions
end

class PairedToken < GenericToken
    # a regex describing which character(s) permit this state change to happen
    def initialize(startChar, endChar = startChar)
       @startChar = startChar
       @endChar = endChar
    end 
    
    def accepts(assemblyView)
        answer = 0
        c = assemblyView.peek 
        if c != @startChar
            return 0
        else
            answer += c.length
        end

        loop do
            if assemblyView.isFinished(answer)
                log "#{@startChar}.*#{@endChar} accepted #{assemblyView.lookAhead(answer)}"
                log "word is #{assemblyView.peekWord}"
                return answer 
            end
            c = assemblyView.peek(answer)
            if c == @endChar || c.nil?
                if ! c.nil?
                    answer += c.length 
                end
                log "#{@startChar}.*#{@endChar} accepted #{assemblyView.lookAhead(answer)}"
                log "word is #{assemblyView.peekWord}"
                return answer 
            else
                answer += c.length
            end
        end
        log "#{@startChar}.*#{@endChar} accepted #{assemblyView.lookAhead(answer)}"
        log "word is #{assemblyView.peekWord}"
        return answer 
    end
end

class RegexToken < GenericToken
    def initialize(regex)
       @regex = regex
    end 
    
    def accepts(assemblyView)
        if match = assemblyView.consumable.match( /^(#{@regex})/ )
            answer = match.captures[0] 
            log "'#{@regex}' accepted #{answer}"
            return answer.length
        else
            return 0
        end
    end
end

class OneAtATimeToken < GenericToken
    def initialize(regex)
       @regex = regex
    end 
    
    def accepts(assemblyView)
        c = assemblyView.peek
        if c =~ /#{@regex}/
            log "'#{@regex}' accepted #{c}"
            return c.length
        else
            return 0
        end
    end
end
