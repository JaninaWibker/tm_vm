ID = '[_a-zA-Z]+[_a-zA-Z0-9]*'

def tm_array(contents)
  inner = '((?:' + contents + '\s*,\s*)*(?:' + contents + '))?'
  '\[\s*' + inner + '\s*\]'
end

def tm_array_no_capture(contents)
  inner = '(?:(?:' + contents + '\s*,\s*)*(?:' + contents + '))?'
  '\[\s*' + inner + '\s*\]'
end

def tm_object(contents)
  inner = '((?:(' + ID + '):\s*' + contents + '\s*,\s*)*(?:(' + ID + '):\s*' + contents + '))?'
  '\{\s*' + inner + '\s*\}'
end

def tm_assignment(lefthandside, righthandside)
  lefthandside + '\s*=\s*' + righthandside
end

def tm_string()
  '(?:"([^"]*)")|(?:\'([^\']*)\')'
end

def tm_string_no_capture()
  '(?:"[^"]*")|(?:\'[^\']*\')'
end

def tm_section(ident)
  '\n?%\s?' + ident + '\s?%\n'
end

def tm_transition()
  '((?:' + tm_string_no_capture() + '|' + ID + ')\s*\|\s*(?:' + tm_string_no_capture() + '|' + ID + ')\s*)' +
    '(?:(?:->\s*' + ID + '\s*)|' +
       '(?:<>\s*'         + '))' +
    '(?:\+|\-|\/)'
end

def tm_transition_no_capture()
  '(?:(?:' + tm_string_no_capture() + '|' + ID + ')\s*\|\s*(?:' + tm_string_no_capture() + '|' + ID + ')\s*)' +
    '(?:(?:->\s*' + ID + '\s*)|' +
       '(?:<>\s*'         + '))' +
    '(?:\+|\-|\/)'
end

def tm_parse_array(str, type_re)
  str.split(Regexp.new '(' + type_re + ')\s*,\s*')
end

def tm_parse_transition(str)
  transition_re = Regexp.new '(?:(' + ID + ')|(?:' + tm_string() + '))\s*\|\s*' +
                             '(?:(' + ID + ')|(?:' + tm_string() + '))' +
                             '(?:\s*(->)\s*(' + ID + ')\s*|\s*(<>)\s*)' +
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
  states_re = Regexp.new tm_assignment(
    'states',
    tm_array(ID + '\s*\$[^\$]+\$')
  )

  inputs_re = Regexp.new tm_assignment(
    'inputs',
    tm_array(tm_string())
  )

  aliases_re = Regexp.new tm_assignment(
    'aliases',
    tm_object(tm_array(tm_string()))
  )

  transitions_re = Regexp.new tm_assignment(
    'transitions',
    tm_object(tm_array(tm_transition_no_capture()))
  )

  states = states_re.match(description) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + ID + ')\s*\$([^\$]+)\$(?:,\s*)?')
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
      .split(Regexp.new '\s*(' + ID + '):\s*' + tm_array(tm_string_no_capture()) + '(?:,\s*)?')
      .select { |str| str != "" }
    ]
      .map { |k,v| [k, tm_parse_array(v, tm_string_no_capture())] }
      .map { |k,v| [
        k,
        v
          .filter { |str| str != '' }
          .map    { |str| str.match(Regexp.new tm_string()).captures[1] }
      ] }.to_h
  }

  transitions = transitions_re.match(description) { |match|
    transitions_arr = match.captures[0]
      .split(Regexp.new '\s*(' + ID + '):\s*' + tm_array(tm_transition_no_capture()) + '(?:,\s*)?')
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

      if (nxt =~ Regexp.new(ID)) != 0 && nxt != nil
        obj[cur] = tm_parse_array(nxt, tm_transition_no_capture())
                    .filter { |str| str != '' }
                    .map { |str| tm_parse_transition str }
        skip_next = true
      else
        obj[cur] = []
      end
    end

    obj
  }

  # TODO: check that all referenced aliases actually exist and similar

  return {
    :states  => states,
    :inputs  => inputs,
    :aliases => aliases,
    :transitions => transitions
  }
end

def parse_execution(execution)

  input_re = Regexp.new tm_assignment(
    'input',
    tm_array(tm_string())
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

  _, *sections = input.split(Regexp.new tm_section('(DESCRIPTION|EXECUTION|OPTIONS)'))
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

