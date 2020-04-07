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

def tm_remove_comments(input)
  input.gsub(/(?<!\\)#.*/, '').gsub(/\\#/, '#')
end

def parse_tm(input)

  input = tm_remove_comments(input)

  _, *sections = input.split(Regexp.new tm_section('(DESCRIPTION|EXECUTION)'))
  sections = Hash[*sections.map { |x| x.strip }]

  if !sections['DESCRIPTION']
    puts "need DESCRIPTION section in file"
    exit 1
  end

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
    tm_object(
      '' # TODO: add transition stuff here
    )
  )


  states = states_re.match(sections['DESCRIPTION']) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + ID + ')\s*\$([^\$]+)\$(?:,\s*)?')
      .select { |str| str != "" }
    ]
  }

  inputs = inputs_re.match(sections['DESCRIPTION']) { |match|
    match.captures[0]
      .split(Regexp.new '[\'"]([^\']+)[\'"](?:,\s*)?')
      .select { |str| str != "" }
  }
  # TODO: parse "'a', 'b', 'c'" into an actual array
  aliases = aliases_re.match(sections['DESCRIPTION']) { |match|
    Hash[*match.captures[0]
      .split(Regexp.new '\s*(' + ID + '):\s*' + tm_array(tm_string_no_capture()) + '(?:,\s*)?')
      .select { |str| str != "" }
    ]
  }

  transitions = transitions_re.match(sections['DESCRIPTION']) { |match|
    puts match.captures[0]
  }

  return {
    :states => states,
    :inputs => inputs,
    :aliases => aliases
  }
end

