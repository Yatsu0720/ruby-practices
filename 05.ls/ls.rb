#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

MAX_COLUMN = 3
PERMISSION_CONVERSION = { '0' => '---', '1' => '--x', '2' => '-w-', '3' => '-wx', '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx' }.freeze
FILE_STAT_CONVERSION = { '10' => '-', '04' => 'd', '12' => 'l' }.freeze

def main
  options = ARGV.getopts('l')
  if options['l']
    puts("total #{fetch_long_format_list.sum { |block_size| block_size[:blocks_size] }}")
    transpose_list
  else
    output_no_option
  end
end

def output_no_option
  max_word_of_characters = fetch_file_name_list.max_by(&:length).length
  max_row = fetch_file_name_list.size / MAX_COLUMN + 1

  separated_list = fetch_file_name_list.each_slice(max_row).to_a

  formatted_list = separated_list.map do |file_name_list|
    file_name_list.values_at(0..max_row - 1).map do |file_name|
      file_name.to_s.ljust(5 + max_word_of_characters)
    end
  end
  puts formatted_list.transpose.map(&:join)
end

def transpose_list
  ljust_file_name = classify_list(:file_name).map { |file_name| file_name.ljust(0) }
  long_format_list = [rjust_list_one_space(:permission), rjust_list_one_space(:hard_link), rjust_list_one_space(:user),
                      rjust_list_two_space(:group), rjust_list_two_space(:file_size), rjust_list_one_space(:time), ljust_file_name].transpose

  long_format_list.each { |long_format_file| puts(long_format_file.join(' ')) }
end

def rjust_list_one_space(key)
  classified_list = classify_list(key)

  maximum_number_of_characters = classified_list.max_by(&:length).length.to_i

  classified_list.map { |item| item.rjust(maximum_number_of_characters, ' ') }
end

def rjust_list_two_space(key)
  classified_list = classify_list(key)

  maximum_number_of_characters = classified_list.max_by(&:length).length.to_i
  classified_list.map { |item| item.rjust(maximum_number_of_characters + 1, ' ') }
end

def classify_list(key)
  hash = fetch_long_format_list

  classified_list = []

  hash.each_with_index do |_x, i|
    classified_list << hash[i][key]
  end
  classified_list
end

def fetch_long_format_list
  long_format_list = []

  fetch_file_name_list.each do |file|
    file_stat = File.stat("#{fetch_directory}/#{file}")
    stat_numbers = file_stat.mode.to_s(8).rjust(6, '0').split('')
    file_type = FILE_STAT_CONVERSION[stat_numbers[0] + stat_numbers[1]]
    file_stat_chars = file_type + PERMISSION_CONVERSION[stat_numbers[3]] + PERMISSION_CONVERSION[stat_numbers[4]] + PERMISSION_CONVERSION[stat_numbers[5]]

    long_format_list << { blocks_size: file_stat.blocks, permission: file_stat_chars, hard_link: file_stat.nlink.to_s, user: Etc.getpwuid(file_stat.uid).name,
                          group: Etc.getgrgid(file_stat.gid).name, file_size: file_stat.size.to_s, time: file_stat.mtime.strftime('%b %d %R'), file_name: file }
  end
  long_format_list
end

def fetch_file_name_list
  Dir.foreach(fetch_directory).to_a.reject { |file_name| file_name.start_with?('.') }.sort
end

def fetch_directory
  if ARGV[1]
    ARGV[1]
  elsif ARGV[0].nil? || ARGV[0].start_with?('-')
    '.'
  else
    ARGV[0]
  end
end

main
