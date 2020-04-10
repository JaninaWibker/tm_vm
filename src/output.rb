require 'fileutils'

def mkdir_if_not_exists(path)
  dirname = File.dirname(path)
  unless File.directory?(dirname)
    FileUtils.mkdir_p(dirname)
  end
end

def output_begin(tm, options)
  template = nil
  begin
    template = File.read(options.template)
  rescue Errno::ENOENT => e
    $stderr.puts "File '#{options.template}' not found: #{e}"
    exit 1
  end

  mkdir_if_not_exists("output")

  return { :template => template, :output => Array.new(10) }
end

def output_stream(output, tm, options, state)
  puts state

  # output[:output][state[:step]] = output[:template].gsub! ...

  return output
end

def output_end(output, tm, options)
  puts output
end
