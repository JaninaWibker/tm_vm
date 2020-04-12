require 'pp'

require_relative './cli.rb'
require_relative './parse.rb'
require_relative './transform.rb'
require_relative './generate_template.rb'
require_relative './run.rb'
require_relative './output.rb'

def main(args)
  cli_options = parse_args(args)
  if cli_options[:filepath] == nil
    puts "must include a file path"
    exit 1
  end

  parsed = nil

  begin
    parsed = parse_tm(File.read(cli_options[:filepath]))
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{cli_options[:filepath]}' not found: #{e}"
  end

  options = { :output => 'tex', :expand_aliases => true, :duration => 500, :filepath => nil, :template => nil }
    .merge(parsed[:options].delete_if { |k, v| v.nil? })
    .merge(cli_options.delete_if { |k, v| v.nil? })

  puts "options: " + options.inspect

  parsed[:description] = transform(parsed[:description], options)

  puts "skipped generating files for testing purposes"
  exit 0

  if options[:template] != nil
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
