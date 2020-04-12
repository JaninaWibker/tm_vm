require_relative './core_ext.rb'

VERSION = 0.1

def parse_args(args)
  options = {
      :output         => nil,
      :expand_aliases => nil,
      :duration       => nil,
      :filepath       => nil,
      :template       => nil
  }

  if args.length == 0
    puts %{usage: ruby main.rb <optional flags> <input file>

flags:
  -o, --output     Specify the output format (tex, svg, gif, react, default: svg)
  -t, --template   Specify the file that should be used as a template for the output
  -e, --expand     Expand aliases
  -E, --no-expand  Don't expand aliases
  -d, --duration   Duration between state transitions (ms)
  -v, --version    Print version
}
  exit 0
  else

    input_file = args.last

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
          if ['tex', 'svg', 'gif', 'react'].include? args[index+1]
            options[:output] = [args[index+1]]
            skip_next = true
          else
            puts "invalid option for '--output', supplied '#{args[index+1]}' but was expecting one of 'tex', 'svg', 'gif' or 'react'"
            exit 1
          end
        end

        if value == '--template'
          # assume next arg is a filepath
          if !args[index+1].start_with? '-'
            options[:template] = File.join(Dir.pwd, args[index+1])
            skip_next = true
          else
            puts "invalid option for '--template', supplied '#{args[index+1]}' but was expecting a filepath"
            exit 1
          end
        end

        if value == '--duration'
          if (args[index+1] =~ /^[0-9]+$/) != nil
            options[:duration] = args[index+1].to_i
          else
            puts "invalid option for '--duration', supplied '#{args[index+1]}' but was expecting a number"
            exit 1
          end
        end

        if value == '--expand'
          options[:expand_aliases] = true
        end

        if value == '--no-expand'
          options[:expand_aliases] = false
        end
        # place other options here

      elsif value.start_with?('-')

        for flag in value[1..-1].split("")

          puts flag

          if flag == 'v'
            puts "version #{VERSION}"
            exit  0
          end

          if flag == 'o'
            if ['tex', 'svg', 'gif', 'react'].include? args[index+1]
              options[:output] = [args[index+1]]
              skip_next = true
            else
              puts "invalid option for '-o', supplied '#{args[index+1]}' but was expecting one of 'tex', 'svg', 'gif' or 'react'"
              exit 1
            end
          end

          if flag == 't'
            # assume next arg is a filepath
            if !args[index+1].start_with? '-'
              options[:template] = File.join(Dir.pwd, args[index+1])
              skip_next = true
            else
              puts "invalid option for '-t', supplied '#{args[index+1]}' but was expecting a filepath"
              exit 1
            end
          end

          if flag == 'd'
            if (args[index+1] =~ /^[0-9]+$/) != nil
              options[:duration] = args[index+1].to_i
            else
              puts "invalid option for '-d', supplied '#{args[index+1]}' but was expecting a number"
              exit 1
            end
          end

          if flag == 'e'
            options[:expand_aliases] = true
          end

          if flag == 'E'
            options[:expand_aliases] = false
          end
        end

      elsif index == args.size-1
        options[:filepath] = File.join(Dir.pwd, value)
      end

    end

  end
  return options
end
