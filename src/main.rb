require 'pp'

require_relative './cli.rb'
require_relative './parse.rb'
require_relative './transform.rb'
require_relative './generate_template.rb'
require_relative './run.rb'
require_relative './output.rb'

def main(args)
  options = parse_args(args)
  if options.filepath == nil
    puts "must include a file path"
    exit 1
  end

  puts "options: " + options.inspect

  parsed = nil

  begin
    parsed = parse_tm(File.read(options.filepath))
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{options.filepath}' not found: #{e}"
  end

  # TODO: combine cli options and file options into one (cli takes precedence)

  parsed[:description] = transform(parsed[:description], options)

  if options.template != nil
    output = output_begin(parsed, options)
    run(parsed) do |state|
      output = output_stream(output, parsed, options, state)
    end
    output_end(output, parsed, options)
  else
    File.write(
      options.filepath + '.tex',
      generate_template(parsed[:description], options)
    )
  end

end

main(ARGV)
