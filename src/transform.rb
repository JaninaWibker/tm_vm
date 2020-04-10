
def transform_transition(states, symbols, aliases, full_aliases, k, t, options)
  if t[:from_id] && !(aliases.include? t[:from_symbol]) && t[:from_symbol] != "BLANK"
    puts "unknown alias '#{t[:from_symbol]}' in transitions (#{k}, from)"
    exit 1
  end

  if t[:to_id] && !(aliases.include? t[:to_symbol]) && t[:to_symbol] != "BLANK"
    puts "unknown alias '#{t[:to_symbol]}' in transitions (#{k}, to)"
    exit 1
  end

  if !t[:from_id] && !(symbols.include? t[:from_symbol])
    puts "unknown symbol '#{t[:from_symbol]}' in transitions (#{k}, from)"
    exit 1
  end

  if !t[:to_id] && !(symbols.include? t[:to_symbol])
    puts "unknown symbol '#{t[:to_symbol]} in transitions (#{k}, to)"
    exit 1
  end

  if !t[:loop] && !(states.include? t[:to_state])
    puts "unknown state '#{t[:to_state]}' in transitions (#{k})"
    exit 1
  end

  if t[:to_state] == k
    t[:loop] = true
  end

  if t[:loop]
    t[:to_state] = k
  end

  if t[:to_id] && t[:to_symbol] != t[:from_symbol] && t[:to_symbol] != 'BLANK'
    puts "invalid transition (#{k}), cannot transition to alias that is differs from input"
    exit 1
  end

  if options.expand_aliases
    if t[:from_id] && t[:from_symbol] != 'BLANK'
      symbols = full_aliases[t[:from_symbol]]

      copy_to = t[:to_id] && t[:to_symbol] != 'BLANK'

      if copy_to
        return symbols.map { |s|
          {
            :from_symbol => s,
            :from_id     => false,
            :to_symbol   => s,
            :to_id       => false,
            :from_state  => k,
            :to_state    => t[:to_state],
            :loop        => t[:loop],
            :direction   => t[:direction]
          }
        }

      else
        return symbols.map { |s|
          {
            :from_symbol => s,
            :from_id     => false,
            :to_symbol   => t[:to_symbol],
            :to_id       => t[:to_id],
            :from_state  => k,
            :to_state    => t[:to_state],
            :loop        => t[:loop],
            :direction   => t[:direction]
          }
        }
      end
    end
  end

  return [t]
end

def transform(description, options)
  states =  description[:states].keys
  symbols = description[:inputs]
  aliases = description[:aliases].keys
  full_aliases = description[:aliases]

  if !states.include? description[:start]
    puts "start state does not exist (#{description[:start]})"
    exit 1
  end

  description[:transitions] = description[:transitions].map { |k,v|
    if !(states.include? k)
      puts "unknown state '#{k}' in transitions"
      exit 1
    end

    next [
      k,
      v.map { |t|
        transform_transition(states, symbols, aliases, full_aliases, k, t, options)
      }.flatten
    ]
  }.to_h
  return description
end
