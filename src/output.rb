require 'fileutils'
require 'tmpdir'

require_relative './tm_re.rb'

def tex2svg(basedir, basename)
  Dir.mktmpdir { |dir|
    system "latex -interaction=nonstopmode -output-directory=#{dir} #{File.join(basedir, basename + '.tex')} >/dev/null"
    system "dvisvgm --output=#{File.join(basedir, basename)}.svg #{File.join(dir, basename)}.dvi 2&>/dev/null"
  }
end

def mkdir_if_not_exists(path)
  dirname = File.join(Dir.pwd, path)
  Dir.mkdir dirname unless File.exists?(dirname)
end

# TODO: differentiate between different output formats
# TODO: implement different output formats

def output_begin(tm, options)
  template = nil
  begin
    template = File.read(options.template)
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{options.template}' not found: #{e}"
    exit 1
  end

  mkdir_if_not_exists("output")

  return { :template => template, :output => Array.new(tm[:execution][:steps]) }
end

def output_stream(output, tm, options, state)

  symbol_re_prepared = state[:symbol] == nil ? 'BLANK' : state[:symbol].include?("'") ?
    ('"' + state[:symbol] + '"') :
    ("'" + state[:symbol] + "'")

  not_symbol_re = "(?:(?!#{symbol_re_prepared})(?:#{TM.string_no_capture()}|#{TM::ID}))"

  symbol_re = "(?:(?:(?:#{not_symbol_re},\\s*)*(?:#{symbol_re_prepared}),\\s*(?:#{not_symbol_re},\\s*)*#{not_symbol_re})|(?:#{not_symbol_re},\\s*)*#{symbol_re_prepared})"

  edge_re = "\\\\TMVMEDGE\\{#{state[:state]}\\}\\{#{symbol_re}\\}"

  template = (output[:template]
    .gsub(Regexp.new("\\\\TMVMNODE\\{#{state[:state]}\\}"), 'highlight' + (' ' * (2 + state[:state].size)))
    .gsub(Regexp.new(edge_re)) { |capture|
      'highlight' + (' ' * (capture.size - 'highlight'.size))
    }
    .gsub('% TM_VM_REPLACE_CURR_STATE %', state[:state])
    .gsub('% TM_VM_REPLACE_CURR_SYMBOL %', state[:symbol] == nil ? '\\square' : state[:symbol])
    .gsub('% TM_VM_REPLACE_COMPLETE_INPUT %', tm[:execution][:input].join(''))
    .gsub('% TM_VM_REPLACE_COMPLETE_TAPE %', state[:tape].join(''))
    .gsub('% TM_VM_REPLACE_STEP %', state[:step].to_s)
  )

  output[:output][state[:step]] = template

  return output
end

def output_end(output, tm, options)
  output[:output].each_with_index { |content, index|
    basedir = File.join(Dir.pwd, "output")
    basename = File.basename(options.filepath) + "-#{index}"
    File.write(File.join(basedir, basename + ".tex"), content)
    tex2svg(basedir, basename)
  }
end
