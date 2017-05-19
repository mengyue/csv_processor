require 'digest'

def process_file(dir, in_path, out_path, cols, with_header, pick_cols, encrypt_cols, encrypt_method, delimiter)
  begin
    in_file = File.open("#{dir}/#{in_path}", 'r')
    out_file = File.new("#{dir}/#{out_path}", 'w')

    if with_header
      writeline(in_file.readline, out_file, pick_cols, encrypt_cols, encrypt_method, delimiter, true)
    end

    lines = 0

    while line = in_file.readline
      writeline(line, out_file, pick_cols, encrypt_cols, encrypt_method, delimiter)
      lines += 1
    end

  rescue Errno::ENOENT => e
    abort('File does NOT Exists')
  rescue EOFError => e
    puts "Records: #{lines}"
  ensure
    in_file.close unless in_file.nil?
    out_file.close unless out_file.nil?
  end
end

def writeline(in_line, out_file, pick_cols, encrypt_cols, encrypt_method, delimiter, is_header=false)
  in_cells = in_line.split(delimiter)
  out_cells = []
  in_cells.each_index do |index|
    next unless pick_cols.include?(index)
    if encrypt_cols.include?(index) && !is_header
      # out_cells << Digest::SHA256.hexdigest(in_cells[index])
      out_cells << Object.const_get("Digest::#{encrypt_method.upcase}").hexdigest(in_cells[index])
    else
      out_cells << in_cells[index]
    end
  end
  out_file.puts(out_cells.join(delimiter))
end

# Example: ruby csv_processor.rb --dir='/Users/carrot/Data/downloads' --in=sample.csv --out=sample_out.csv --encrypt_cols=1 --encrypt_method=sha256 --cols=3 --with_header=true --pick_cols=1,2

abort('NO argument') if ARGV.empty?

args = {}

ARGV.each do |arg|
  match = /--(?<key>.*?)=(?<value>.*)/.match(arg)
  args[match[:key]] = match[:value]
end

dir = args['dir']
in_path = args['in']
out_path = args['out']
cols = args['cols']

abort('Missing arguments') unless dir && in_path && out_path && cols

with_header = args['with_header']
pick_cols = args['pick_cols'].nil? ? (0..cols.to_i-1).to_a : args['pick_cols'].split(',').map {|c| c.to_i}
encrypt_cols = args['encrypt_cols'].nil? ? (0..cols.to_i-1).to_a : args['encrypt_cols'].split(',').map {|c| c.to_i}
encrypt_method = args['encrypt_method']
delimiter = args['delimiter'] || ','

abort('DIR does NOT Exists.') if dir.nil? || !Dir.exist?(dir)

process_file(dir, in_path, out_path, cols, with_header, pick_cols, encrypt_cols, encrypt_method, delimiter)
