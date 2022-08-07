#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

MAX_COLUMN = 3
PERMISSION_CONVERSION = { '0' => '---', '1' => '--x', '2' => '-w-', '3' => '-wx', '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx' }.freeze
FILE_STAT_CONVERSION = { '10' => '-', '04' => 'd', '12' => 'l' }.freeze

def main
  l_command = false
  opts = OptionParser.new
  opts.on('-l'){l_command = true}
  opts.parse!(ARGV)

  file_stats = fetch_file_stat_list[0]
  total_block_size = make_file_stat_list(file_stats).sum { |block_size| block_size[:blocks_size] }
  if l_command
    puts("total #{total_block_size}")
    print_file_list(file_stats)
  else
    output_no_option
  end
end

def output_no_option
  file_names = fetch_file_stat_list[1]
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

def print_file_list(file_stats)
  hard_link_padding, user_padding, group_padding, file_size_padding = calculate_padding(file_stats)
  files_list = make_file_stat_list(file_stats)
  files_list.each do |file_list|
    print file_list[:permission].ljust(10, ' ')
    print file_list[:hard_link].rjust(hard_link_padding, ' ')
    print file_list[:user].rjust(user_padding, ' ')
    print file_list[:group].rjust(group_padding, ' ')
    print file_list[:file_size].rjust(file_size_padding, ' ')
    print file_list[:time]
    puts file_list[:file_name]
  end
end

def calculate_padding(file_stats)
  classified_list = classify_list(file_stats)
  margin = margin_list
  hard_link_max_characters = classified_list[:hard_link].flatten.max_by(&:length).length.to_i
  user_max_characters = classified_list[:user].flatten.max_by(&:length).length.to_i
  group_max_characters = classified_list[:group].flatten.max_by(&:length).length.to_i
  file_size_max_characters = classified_list[:file_size].flatten.max_by(&:length).length.to_i

  hard_link_padding = hard_link_max_characters + margin[:hard_link]
  user_padding = user_max_characters + margin[:user]
  group_padding = group_max_characters + margin[:group]
  file_size_padding = file_size_max_characters + margin[:file_size]
  [hard_link_padding, user_padding, group_padding, file_size_padding]
end

def margin_list
  margin = {}
  margin[:hard_link] = 1
  margin[:user] = 1
  margin[:group] = 2
  margin[:file_size] = 2
  margin
end

def classify_list(file_stats)
  array = make_file_stat_list(file_stats)
  {}.merge(*array) { |_key, former_value, after_value| [former_value, after_value] }
end

def make_file_stat_list(file_stats)
  file_name = fetch_file_stat_list[1]
  file_stats.map.with_index do |file_stat, i|
    { blocks_size: file_stat.blocks,
      permission: convert_file_stat_chars(file_stat),
      hard_link: file_stat.nlink.to_s,
      user: Etc.getpwuid(file_stat.uid).name,
      group: Etc.getgrgid(file_stat.gid).name,
      file_size: file_stat.size.to_s,
      time: file_stat.mtime.strftime(' %b %e %R '),
      file_name: file_name[i] }
  end
end

def convert_file_stat_chars(file_stat)
  file_type = FILE_STAT_CONVERSION[file_stat.mode.to_s(8).rjust(6, '0')[0, 2]]
  converted_file_stat = file_stat.mode.to_s(8).rjust(6, '0')
  owner_permission = PERMISSION_CONVERSION[converted_file_stat[3]]
  group_permission = PERMISSION_CONVERSION[converted_file_stat[4]]
  other_permission = PERMISSION_CONVERSION[converted_file_stat[5]]
  file_type + owner_permission + group_permission + other_permission
end

def fetch_file_stat_list
  ls_dir = ARGV[0] || '.'
  Dir.chdir(ls_dir) do
    file_names = Dir.glob('*').sort
    files_stat = file_names.map do |file|
      File.stat("#{ls_dir}/#{file}")
    end
    return files_stat, file_names
  end
end

main
