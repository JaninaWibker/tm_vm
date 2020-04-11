require 'fileutils'
require 'tmpdir'

def tm_string_no_capture()
  '(?:"[^"]*")|(?:\'[^\']*\')'
end

ID = '[_a-zA-Z]+[_a-zA-Z0-9]*'

def mkdir_if_not_exists(path)
  dirname = File.dirname(path)
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end

def output_begin(tm, options)
  template = nil
  begin
    template = File.read(options.template)
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{options.template}' not found: #{e}"
    exit 1
  end

  mkdir_if_not_exists("output")

  return { :template => template, :output => Array.new(10) }
end

def output_stream(output, tm, options, state)
  puts state

  # TODO: use prev_symbol / prev_state or symbol / state? (consider that :prev_symbol is nil at first)

  symbol_re_prepared = state[:prev_symbol] == nil ? 'BLANK' : state[:prev_symbol].include?("'") ?
    ('"' + state[:prev_symbol] + '"') :
    ("'" + state[:prev_symbol] + "'")

  not_symbol_re = "(?:(?!#{symbol_re_prepared})(?:#{tm_string_no_capture()}|#{ID}))"

  symbol_re = "(?:(?:(?:#{not_symbol_re},\\s*)*(?:#{symbol_re_prepared}),\\s*(?:#{not_symbol_re},\\s*)*#{not_symbol_re})|(?:#{not_symbol_re},\\s*)*#{symbol_re_prepared})"

  edge_re = "\\\\TMVMEDGE\\{#{state[:state]}\\}\\{#{symbol_re}\\}"

  template = (output[:template]
    .gsub(Regexp.new("\\\\TMVMNODE\\{#{state[:prev_state]}\\}"), 'highlight' + (' ' * (2 + state[:prev_state].size)))
    .gsub(Regexp.new(edge_re)) { |capture|
      'highlight' + (' ' * (capture.size - 'highlight'.size))
    }
    .gsub('% TM_VM_REPLACE_CURR_STATE %', state[:state])
    .gsub('% TM_VM_REPLACE_CURR_SYMBOL %', state[:symbol] == nil ? '\\square' : state[:symbol])
    .gsub('% TM_VM_REPLACE_COMPLETE_INPUT %', tm[:execution][:input].join(''))
    .gsub('% TM_VM_REPLACE_COMPLETE_TAPE %', state[:tape].join(''))
    .gsub('% TM_VM_REPLACE_STEP %', state[:step].to_s)
  )
  puts template

  output[:output][state[:step]] = template

  return output
end

def output_end(output, tm, options)
  puts output
end
