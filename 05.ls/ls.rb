#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

MAX_COLUMN = 3

def main
  options = ARGV.getopts('a')
  ls_dir = ARGV[0] || '.'

  directory_list = Dir.foreach(ls_dir).to_a

  directory_list = directory_list.to_a.reject { |i| /^\./.match?(i) == true } if options['a']

  max_word_count = directory_list.max_by(&:length).length
  max_row = directory_list.size / MAX_COLUMN + 1

  separated_list = directory_list.sort.each_slice(max_row).to_a

  sorted_list = separated_list.map do |file_names|
    file_names.values_at(0..max_row - 1).map do |file_name|
      file_name ||= ''
      file_name.ljust(5 + max_word_count)
    end
  end

  puts sorted_list.transpose.map(&:join)
end

main