module TM

  ID = '[_a-zA-Z]+[_a-zA-Z0-9]*'

  def TM.array(contents)
    inner = '((?:' + contents + '\s*,\s*)*(?:' + contents + '))?'
    '\[\s*' + inner + '\s*\]'
  end

  def TM.array_no_capture(contents)
    inner = '(?:(?:' + contents + '\s*,\s*)*(?:' + contents + '))?'
    '\[\s*' + inner + '\s*\]'
  end

  def TM.object(contents)
    inner = '((?:(' + TM::ID + '):\s*' + contents + '\s*,\s*)*(?:(' + TM::ID + '):\s*' + contents + '))?'
    '\{\s*' + inner + '\s*\}'
  end

  def TM.assignment(lefthandside, righthandside)
    lefthandside + '\s*=\s*' + righthandside
  end

  def TM.string()
    '(?:"([^"]*)")|(?:\'([^\']*)\')'
  end

  def TM.string_no_capture()
    '(?:"[^"]*")|(?:\'[^\']*\')'
  end

  def TM.section(ident)
    '\n?%\s?' + ident + '\s?%\n'
  end

  def TM.transition()
    '((?:' + TM.string_no_capture() + '|' + TM::ID + ')\s*\|\s*(?:' + TM.string_no_capture() + '|' + TM::ID + ')\s*)' +
      '(?:(?:->\s*' + TM::ID + '\s*)|' +
         '(?:<>\s*'         + '))' +
      '(?:\+|\-|\/)'
  end

  def TM.transition_no_capture()
    '(?:(?:' + TM.string_no_capture() + '|' + TM::ID + ')\s*\|\s*(?:' + TM.string_no_capture() + '|' + TM::ID + ')\s*)' +
      '(?:(?:->\s*' + TM::ID + '\s*)|' +
         '(?:<>\s*'         + '))' +
      '(?:\+|\-|\/)'
  end

  def TM.parse_array(str, type_re)
    str.split(Regexp.new '(' + type_re + ')\s*,\s*')
  end

end
