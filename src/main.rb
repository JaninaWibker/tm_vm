require './src/cli.rb'
require './src/parse.rb'

def main(args)
  options = parse_args(args)
  if options.filepath == nil
    puts "must include a file path"
    exit 1
  end
  puts options.inspect

  puts parse_tm(File.read(options.filepath))
end

main(ARGV)
