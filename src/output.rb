require 'fileutils'
require 'tmpdir'
require 'set'

require_relative './tm_re.rb'

def tex2svg(basedir, basename, options)
  font_option = options[:font_mode] == 'no-font' ? '--no-fonts' :
                options[:font_mode] == 'woff' ? '--font-format=woff' : ''

  Dir.mktmpdir { |dir|
    system "latex -interaction=nonstopmode -output-directory=#{dir} #{File.join(basedir, basename + '.tex')} >/dev/null"
    system "dvisvgm #{font_option} --output=#{File.join(basedir, basename)}.svg #{File.join(dir, basename)}.dvi 2&>/dev/null"
  }
end

def svg2png(basedir, basename, options)
  flags = [
    "--export-background=#{options[:bg] || "ffffff"}",
    "--export-background-opacity=#{(options[:bg_opacity] || 255).to_s}",
    "--export-dpi=#{(options[:dpi] || 300).to_s}",
    "--export-filename=#{File.join(basedir, basename)}.png",
    File.join(basedir, basename) + ".svg"
  ]

  system "inkscape #{flags.join(" ")} 2&>/dev/null"
end

def pngs2gif(basedir, inputfiles, outputfile, options)
  flags = [
    "-loop #{options[:loop]}",
    "-delay #{(options[:duration] || 500) / 10}",
    *(inputfiles.map { |basename| File.join(basedir, basename) }),
    File.join(basedir, outputfile)
  ]

  system "convert #{flags.join(" ")} 2&>/dev/null"
end

def tex2pdf(basedir, basename, options)
  Dir.mktmpdir { |dir|
    flags = [
      "-interaction=nonstopmode",
      "-output-directory=#{dir}",
      File.join(basedir, basename + '.tex')
    ]
    system "pdflatex #{flags.join(" ")} &>/dev/null"
    File.rename(File.join(dir, basename + '.pdf'), File.join(basedir, basename + '.pdf'))
   }
end

def mkdir_if_not_exists(path)
  dirname = File.join(Dir.pwd, path)
  Dir.mkdir dirname unless File.exists?(dirname)
end

def output_begin(tm, options)
  template = nil
  begin
    template = File.read(options[:template])
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{options[:template]}' not found: #{e}"
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

  sorted_output = Set.new []
  sorted_output.merge ["tex"]                        if options[:output].include? "tex"
  sorted_output.merge ["tex", "svg"]                 if options[:output].include? "svg"
  sorted_output.merge ["tex", "svg", "png"]          if options[:output].include? "png"
  sorted_output.merge ["tex", "svg", "png", "gif"]   if options[:output].include? "gif"
  sorted_output.merge ["tex", "pdf"]   if options[:output].include? "pdf"
  sorted_output.merge ["tex", "react"] if options[:output].include? "react"

  # all of these output formats kind of depend on each other:
  # -                           svg requires tex
  # -              png requires svg requires tex
  # - gif requires png requires svg requires tex
  #
  # an exception to this rule are pdf and react:
  # - pdf   does not depend on gif, only on tex
  # - react does not depend on gif, only on tex
  #
  # for this purpose the outputs are sorted here
  # to make it easier to work with

  puts sorted_output.inspect



  basedir = File.join(Dir.pwd, "output")

  puts "output folder is: #{basedir}"

  basename_no_index = File.basename(options[:filepath])


  output[:output].each_with_index { |content, index|
    basename = basename_no_index + "-" + index.to_s

    if sorted_output.include? "tex"
      File.write(File.join(basedir, basename + ".tex"), content)
      puts "written #{basename}.tex"
    end

    if sorted_output.include? "svg"
      tex2svg(basedir, basename, { :font_mode => (sorted_output.include? "png") ? 'no-font' : 'woff' })
      puts "written #{basename}.svg"
    end

    if sorted_output.include? "png"
      svg2png(basedir, basename, { :bg => "ffffff", :bg_opacity => 255, :dpi => 300 })
      puts "written #{basename}.png"
    end

    # gif is handled OUTSIDE of the each_with_index
    # iteration as it requires all pngs to be present

    if sorted_output.include? "pdf"
      tex2pdf(basedir, basename, {})
      puts "written #{basename}.pdf"
    end

    if sorted_output.include? "react"
      puts "react support coming soon" # TODO: add react support
    end
  }

  if sorted_output.include? "gif"
    inputfiles = *(0..output[:output].size-1).map { |index| basename_no_index + "-" + index.to_s + ".png" }

    pngs2gif(
      basedir,
      inputfiles,
      File.basename(options[:filepath] + ".gif"),
      { :loop => 0, :duration => options[:duration] }
    )
  end
end
