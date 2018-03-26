########################
### manages the process of locating completion config files
########################

module ConfigSearch

COMPLETION_CONF_DIRS = [
    "#{ENV['HOME']}/.askbash",
    ENV['ASKBASH_HOME'],
#    File.dirname(__FILE__) 
]

CompletionConf = Struct.new(:command, :configfile)

def allCompletionConfs(locations)
    answer = []
    dupcheck = {} 

    locations.each {|loc|
        completionDir = "#{loc}/completions" 
        log "searching for completion configs in #{completionDir}"
        confs = Dir.glob("#{completionDir}/*.yml")
        if ! confs.nil?
            confs.each { |c|
                cmd = File.basename(c)
                cmd = cmd[0, cmd.length - '.yml'.length]
                if dupcheck[cmd].nil?
                    dupcheck[cmd]=true
                    log "mapping #{cmd} -> #{c}"
                    answer.push CompletionConf.new(cmd, c)
                end
            }
        end
    }
    return answer
end

def completionConfSearch(locations)
    compline = ENV['COMP_LINE'].split
    prog = compline[0]
    log "loading completions for #{prog}"
    locations.each {|loc|
        file = "#{loc}/completions/#{prog}.yml"
        if ! loc.nil? && File.exist?(file)
           return file 
        else
            log "not found: #{file}"
        end
    }
    return nil
end

end
