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
  # TODO: parse "'a', 'b', 'c'" into an actual array
  aliases = aliases_re.match(description) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + ID + '):\s*' + tm_array(tm_string_no_capture()) + '(?:,\s*)?')
      .select { |str| str != "" }
    ]
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
        obj[cur] = nxt.split("\n").map { |x| x.strip }
        skip_next = true
      else
        obj[cur] = []
      end
    end

    obj
  }

  return {
    :states => states,
    :inputs => inputs,
    :aliases => aliases,
    :transitions => transitions
  }
end

def parse_execution(execution)
  return {
    :input => [],
    :steps => 0
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
    :execution => parse_execution(sections['EXECUTION']),
    :options => parse_options(sections['OPTIONS'])
  }
end

