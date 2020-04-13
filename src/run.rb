def change_symbol(tape, pos, symbol)
  if pos == -1
    return { :tape => [symbol] + tape, :new_pos => pos + 1 }
  elsif pos == tape.size
    return { :tape => tape + [symbol], :new_pos => pos - 1 }
  else
    new_tape = tape.map(&:clone)
    new_tape[pos] = symbol
    return { :tape => new_tape, :new_pos => pos }
  end
end

def get_symbol(tape, pos)
  if pos == -1 # out of bounds left side (-> blank symbol, expanding tape left side)
    return { :tape => [nil] + tape, :new_pos => pos + 1, :symbol => nil }
  elsif pos == tape.size # out of bounds right side (-> blank symbol, expanding tape right side)
    return { :tape => tape + [nil], :new_pos => pos - 1, :symbol => nil }
  else # not ouf of bounds, not adjusting tape
    return { :tape => tape,         :new_pos => pos,     :symbol => tape[pos] }
  end
end

def run(tm)
  tape  = tm[:execution][:input]
  steps = tm[:execution][:steps]
  aliases = tm[:description][:aliases]
  transitions = tm[:description][:transitions]

  pos    = 0       # position of the head on the tape
  symbol = tape[0] # next symbol to be processed
  state  = tm[:description][:start] # current state
  prev_symbol = nil # values that might
  prev_state  = nil # be useful renderers

  for i in 0..steps # steps + 1, the 0th step can be seen as the initial state of the tm
    transition = transitions[state].find { |t|
      # could be combined into a single condition but would make it far less readable
      if !t[:from_id] && t[:from_symbol] == symbol
        true
      elsif t[:from_id] && t[:from_symbol] == 'BLANK' && symbol == nil
        true
      elsif t[:from_id] && (aliases[t[:from_symbol]].include? symbol)
        true
      else
        false
      end
    }

    break if transition == nil

    yield ({
      :state      => state,      :prev_state  => prev_state,
      :symbol     => symbol,     :prev_symbol => prev_symbol,
      :tape       => tape,       :position    => pos,
      :transition => transition, :step        => i
    })

    new_symbol = (transition[:to_id] ?
      transition[:to_symbol] == 'BLANK' ? nil : symbol :
      transition[:to_symbol])

    tape, pos = change_symbol(tape, pos, new_symbol).values_at(:tape, :new_pos)
    prev_symbol = symbol
    prev_state = state
    pos += transition[:direction]
    state = transition[:to_state]
    tape, pos, symbol = get_symbol(tape, pos).values_at(:tape, :new_pos, :symbol)

  end
end
