require 'pp'

require './src/cli.rb'
require './src/parse.rb'
require './src/transform.rb'
require './src/generate_template.rb'
require './src/run.rb'
require './src/output.rb'

def main(args)
  options = parse_args(args)
  if options.filepath == nil
    puts "must include a file path"
    exit 1
  end

  puts "options: " + options.inspect

  parsed = parse_tm(File.read(options.filepath))

  # TODO: combine cli options and file options into one (cli takes precedence)

  parsed[:description] = transform(parsed[:description], options)

  pp parsed

  if options.template != nil
    output_begin(parsed, options)
    run(parsed) do |parsed, state|
      output_stream(parsed, options, state)
    end
    output_end(parsed, options)
  else
    File.write(
      options.filepath + '.tex',
      generate_template(parsed[:description], options)
    )
  end

end

main(ARGV)
