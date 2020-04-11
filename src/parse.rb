require './src/tm_re.rb'

def tm_parse_transition(str)
  transition_re = Regexp.new '(?:(' + TM::ID + ')|(?:' + TM.string() + '))\s*\|\s*' +
                             '(?:(' + TM::ID + ')|(?:' + TM.string() + '))' +
                             '(?:\s*(->)\s*(' + TM::ID + ')\s*|\s*(<>)\s*)' +
                             '(\+|\-|\/)'
  str.match(transition_re) { |match|
    from_id, from_dblquote, from_sglquote,
      to_id, to_dblquote, to_sglquote,
      r_arrow, to_state, d_arrow, dir = match.captures

    from_quote = from_dblquote || from_sglquote
    to_quote   = to_dblquote   || to_sglquote

    from_symbol = nil
    to_symbol   = nil
    from_alias  = false
    to_alias    = false
    loop        = false
    direction   = 0

    if from_id == nil
      from_symbol = from_quote
    else
      from_symbol = from_id
      from_alias = true
    end

    if to_id == nil
      to_symbol = to_quote
    else
      to_symbol = to_id
      to_alias = true
    end

    if r_arrow == nil
      loop = true
    end

    if dir== '+'
      direction = 1
    elsif dir== '-'
      direction = -1
    elsif dir== '/'
      direction = 0
    end

    return {
      :from_symbol => from_symbol,
      :from_id     => from_alias,
      :to_symbol   => to_symbol,
      :to_id       => to_alias,
      :from_state  => nil, # to be filled in later (in src/transform.rb)
      :to_state    => to_state,
      :loop        => loop,
      :direction   => direction
    }

  }

  end

def tm_remove_comments(input)
  input.gsub(/(?<!\\)#.*/, '').gsub(/\\#/, '#')
end

def parse_description(description)
  states_re = Regexp.new TM.assignment(
    'states',
    TM.array(TM::ID + '\s*\$[^\$]+\$')
  )

  inputs_re = Regexp.new TM.assignment(
    'inputs',
    TM.array(TM.string())
  )

  aliases_re = Regexp.new TM.assignment(
    'aliases',
    TM.object(TM.array(TM.string()))
  )

  transitions_re = Regexp.new TM.assignment(
    'transitions',
    TM.object(TM.array(TM.transition_no_capture()))
  )

  start_re = Regexp.new TM.assignment(
    'start',
    '(' + TM::ID + ')'
  )

  states = states_re.match(description) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + TM::ID + ')\s*\$([^\$]+)\$(?:,\s*)?')
      .select { |str| str != "" }
    ]
  }

  inputs = inputs_re.match(description) { |match|
    match.captures[0]
      .split(Regexp.new '[\'"]([^\']+)[\'"](?:,\s*)?')
      .select { |str| str != "" }
  }

  aliases = aliases_re.match(description) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + TM::ID + '):\s*' + TM.array(TM.string_no_capture()) + '(?:,\s*)?')
      .select { |str| str != "" }
    ]
      .map { |k,v| [k, TM.parse_array(v, TM.string_no_capture())] }
      .map { |k,v| [
        k,
        v
          .filter { |str| str != '' }
          .map    { |str| str.match(Regexp.new TM.string()).captures[1] }
      ] }.to_h
  }

  transitions = transitions_re.match(description) { |match|
    transitions_arr = match.captures[0]
      .split(Regexp.new '\s*(' + TM::ID + '):\s*' + TM.array(TM.transition_no_capture()) + '(?:,\s*)?')
      .select { |str| str != "" }

    obj = {}

    skip_next = false

    for index in 0 ... transitions_arr.size
      if skip_next
        skip_next = false
        next
      end

      cur = transitions_arr[index]
      nxt = transitions_arr[index+1]

      if (nxt =~ Regexp.new(TM::ID)) != 0 && nxt != nil
        obj[cur] = TM.parse_array(nxt, TM.transition_no_capture())
                    .filter { |str| str != '' }
                    .map { |str| tm_parse_transition str }
        skip_next = true
      else
        obj[cur] = []
      end
    end

    obj
  }

  start = start_re.match(description).captures[0]

  return {
    :states  => states,
    :start   => start,
    :inputs  => inputs,
    :aliases => aliases,
    :transitions => transitions
  }
end

def parse_execution(execution)

  input_re = Regexp.new TM.assignment(
    'input',
    TM.array(TM.string())
  )

  step_re = /step\s+([0-9]+)/

  input = input_re.match(execution) { |match|
    match.captures[0]
      .split(Regexp.new '[\'"]([^\']+)[\'"](?:,\s*)?')
      .select { |str| str != "" }
  }

  step = step_re.match(execution) { |match|
    match.captures[0].to_i
  }

  return {
    :input => input,
    :steps => step
  }
end

def parse_options(options)
  return {
    :output => nil,
    :duration => 0
  }
end

def parse_tm(input)

  input = tm_remove_comments(input)

  _, *sections = input.split(Regexp.new TM.section('(DESCRIPTION|EXECUTION|OPTIONS)'))
  sections = Hash[*sections.map { |x| x.strip }]

  if !sections['DESCRIPTION']
    puts "need DESCRIPTION section in file"
    exit 1
  end

  return {
    :description => parse_description(sections['DESCRIPTION']),
    :execution   => parse_execution(sections['EXECUTION']),
    :options     => parse_options(sections['OPTIONS'])
  }
end

