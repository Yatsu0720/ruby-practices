# frozen_string_literal: true

require 'optparse'
require 'etc'

MAX_COLUMN = 3
PERMISSION_CONVERSION = { '0' => '---', '1' => '--x', '2' => '-w-', '3' => '-wx', '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx' }.freeze
FILE_STAT_CONVERSION = { '10' => '-', '04' => 'd', '12' => 'l' }.freeze

def main
  params = ARGV.getopts('arl')
  opts = OptionParser.new
  opts.parse!(ARGV) || '.'
  ls_dir = ARGV[0] || '.'

  file_stats = make_file_stats(ls_dir, params)
  if params['l']
    print_l_option_files(file_stats)
  else
    print_not_l_option_files(file_stats)
  end
end

def print_not_l_option_files(file_stats)
  file_names = file_stats.map { |file_stat| file_stat[:file_name] }
  max_word_of_characters = file_names.max_by(&:length).length
  max_row = file_names.size / MAX_COLUMN + 1

  separated_list = file_names.each_slice(max_row).to_a

  formatted_list = separated_list.map do |file_name_list|
    file_name_list.values_at(0..max_row - 1).map do |file_name|
      file_name.to_s.ljust(5 + max_word_of_characters)
    end
  end
  puts formatted_list.transpose.map(&:join)
end

def print_l_option_files(file_stats)
  max_lengths = calculate_max_length(file_stats)
  total_block_size = file_stats.sum { |block_size| block_size[:blocks_size] }
  puts "total #{total_block_size}"
  file_stats.each do |file_stat|
    print file_stat[:permission]
    print "#{file_stat[:hard_link].to_s.rjust(max_lengths[:hard_link] + 1)} "
    print file_stat[:user].ljust(max_lengths[:user] + 2)
    print file_stat[:group].ljust(max_lengths[:group] + 2)
    print file_stat[:file_size].to_s.rjust(max_lengths[:file_size])
    print file_stat[:time].strftime(' %_m %e %R ')
    puts file_stat[:file_name]
  end
end

def calculate_max_length(files_stats)
  max_lengths = {}
  files_stats.each do |hash|
    max_lengths[:hard_link] = [max_lengths[:hard_link].to_i, hash[:hard_link].to_s.size].max
    max_lengths[:user] = [max_lengths[:user].to_i, hash[:user].size].max
    max_lengths[:group] = [max_lengths[:group].to_i, hash[:group].size].max
    max_lengths[:file_size] = [max_lengths[:file_size].to_i, hash[:file_size].to_s.size].max
  end
  max_lengths
end

def convert_file_stat_chars(file_stat)
  file_type = FILE_STAT_CONVERSION[file_stat.mode.to_s(8).rjust(6, '0')[0, 2]]
  converted_file_stat = file_stat.mode.to_s(8).rjust(6, '0')
  owner_permission = PERMISSION_CONVERSION[converted_file_stat[3]]
  group_permission = PERMISSION_CONVERSION[converted_file_stat[4]]
  other_permission = PERMISSION_CONVERSION[converted_file_stat[5]]
  file_type + owner_permission + group_permission + other_permission
end

def make_file_stats(ls_dir, params)
  files = fetch_files(ls_dir, params)
  files.map do |file|
    file_stat = File.stat(file)
    file_stats = {}
    file_stats[:blocks_size] = file_stat.blocks
    file_stats[:permission] = convert_file_stat_chars(file_stat)
    file_stats[:hard_link] = file_stat.nlink
    file_stats[:user] = Etc.getpwuid(file_stat.uid).name
    file_stats[:group] = Etc.getgrgid(file_stat.gid).name
    file_stats[:file_size] = file_stat.size
    file_stats[:time] = file_stat.mtime
    file_stats[:file_name] = File.basename(file)
    file_stats
  end
end

def fetch_files(ls_dir, params)
  files = if params['a']
            Dir.glob("#{ls_dir}/*", File::FNM_DOTMATCH).sort
          else
            Dir.glob("#{ls_dir}/*").sort
          end

  if params['r']
    files.reverse
  else
    files
  end
end

main
