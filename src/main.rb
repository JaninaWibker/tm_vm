require 'pp'

require './src/cli.rb'
require './src/parse.rb'
require './src/transform.rb'

def main(args)
  options = parse_args(args)
  if options.filepath == nil
    puts "must include a file path"
    exit 1
  end

  puts options.inspect

  parsed = parse_tm(File.read(options.filepath))

  # TODO: combine cli options and file options into one (cli takes precedence)

  parsed[:description] = transform(parsed[:description], options)

  pp parsed
end

main(ARGV)
