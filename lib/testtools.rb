module TestTools

def expectedIs(a, b)
    b.sort!
    output = AutoCompleter.new(@config, a).parse.sort!
    if output != b
        puts caller 
        puts "for input: #{a}"
        puts "#{output} != #{b}"
        puts ">>> Test FAILED <<<"
        exit
    end
end

def expectedContains(a, b)
    output = AutoCompleter.new(@config, a).parse
    if ! output.member? b
        puts caller 
        puts "for input: #{a}"
        puts "#{output} did not contain '#{b}'"
        puts ">>> Test FAILED <<<"
        exit
    end
end

def expectedLength(a, b)
    output = AutoCompleter.new(@config, a).parse
    if output.length != b
        puts caller 
        puts "for input: #{a}"
        puts "#{output} did not meet expected length of #{b}"
        puts ">>> Test FAILED <<<"
        exit
    end
end

def expectedContainsNot(a, b)
    output = AutoCompleter.new(@config, a).parse
    if output.member? b
        puts caller 
        puts "for input: #{a}"
        puts "#{output} should not contain '#{b}'"
        puts ">>> Test FAILED <<<"
        exit
    end
end

def testArraysEqual(a, b) 
    a.sort!
    b.sort!
    if a != b
        puts caller 
        puts "#{a} != #{b}"
        puts ">>> Test FAILED <<<"
        exit
    end
end

def testArrayContains(a, b) 
    if ! a.member? b
        puts caller 
        puts "#{a} did not contain #{b}"
        puts ">>> Test FAILED <<<"
        exit
    end
end


end
