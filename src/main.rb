require './src/cli.rb'

def main(args)
  options = parse_args(args)
  if options.filepath == nil
    puts "must include a file path"
    exit 1
  end
  puts options.inspect
end

main(ARGV)
