require './src/core_ext.rb'

VERSION = 0.1

class Options
  attr_accessor :output, :filepath

  def initialize()
    @output = "tex"
  end
end



def parse_args(args)
  options = Options.new()

  if args.length == 0
    puts %{usage: ruby main.rb <optional flags> <input file>

flags:
  -o, --output    Specify the output format (tex, svg, react, default: svg)
  -v, --version   Print persion
}
  exit 0
  else

    input_file = args.last


    # there are 3 options:
    # - invoked without any flags / options, just the filepath
    # - invoked with flags / options followed by filepath
    # - invoked without any flags / optinos, except -v / --version, filepath omitted
    # It is not easy to see wether option 1 or 3 was used, therefore it is checked if the last argument
    # starts with "-". This means filepaths cannot start with "-" or they will be recognized as flags
    # if args.length >= 2 or !args.last.start_with?("-") # option 1 or 2
    #   args = args.clip # remove filepath
    # end
    # the assumption that args.last was the filepath was incorrect

    skip_next = false

    for index in 0 ... args.size
      if skip_next
        skip_next = false
       next
      end
      value = args[index]
      if value.start_with?('--')
        if value == '--version'
          puts "version #{VERSION}"
          exit 0
        end

        if value == '--output'
          # next value should be the output format
          if ['tex', 'svg', 'react'].include? args[index+1]
            options.output = args[index+1]
            skip_next = true
          else
            puts "invalid option for '--output', supplied '#{args[index+1]}' but was expecting one of 'tex', 'svg' or 'react'"
            exit 1
          end
        end
        # place other options here

      elsif value.start_with?('-')

        if value == '-v'
          puts "version #{VERSION}"
          exit  0
        end

        if value == '-o'
          if ['tex', 'svg', 'react'].include? args[index+1]
            options.output = args[index+1]
            skip_next = true
          else
            puts "invalid option for '-o', supplied '#{args[index+1]}' but was expecting one of 'tex', 'svg' or 'react'"
            exit 1
          end
        end

      elsif index == args.size-1
        options.filepath = value
      end

    end

  end
  return options
end
