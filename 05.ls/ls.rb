#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

MAX_COLUMN = 3

 
      def print_file_list
  file_list = fetch_file_list

  max_word_count = file_list.max_by(&:length).length
  max_row = file_list.size / MAX_COLUMN + 1

  separated_list = file_list.each_slice(max_row).to_a

  formatted_list = separated_list.map do |file_names|
    file_names.values_at(0..max_row - 1).map do |file_name|
      file_name.to_s.ljust(5 + max_word_count)
    end
  end

  puts formatted_list.transpose.map(&:join)
end

def fetch_file_list
  ll_display = []
  file_state_chars = []
  hard_links = []   
  user_names = []
  group_names = []
  file_sizes = []
  timestamps = [] 

  options = ARGV.getopts('l')
  ls_dir = ARGV[0] || '.'

  file_list = Dir.foreach(ls_dir).to_a.reject { |file_name| file_name.start_with?('.') }
  file_list.each_with_index do |file, integer|
    file_state = File.stat(file)
    file_state_array = file_state.mode.to_s(8).rjust(6, '0').split('')
    
    file_type = if file_state_array[0] + file_state_array[1] == '10'
                  '-'
                elsif file_state_array[0] + file_state_array[1] == '04'
                  'd'
                else
                  'l'
                end
        
    correspondence_table = {'0'=> '---', '1' => '--x', '2' => '-w-', '3' => '-wx', '4' => 'r--', '5' => 'r-x', '6' => 'rw-', '7' => 'rwx'}

    file_state_chars = file_type + correspondence_table[file_state_array[3]] + correspondence_table[file_state_array[4]] + correspondence_table[file_state_array[5]]
    
    ll_display << {file_state: file_state_chars, hard_link: file_state.nlink.to_s, user_name: Etc.getpwuid(file_state.uid).name, group_name: Etc.getgrgid(file_state.gid).name, file_size: file_state.size.to_s, timestamps: file_state.mtime.strftime('%b %d %R')}
  end
 
 # max_hard_link = hard_links.max_by { |hard_link| hard_link.length }.length
 # max_user_name = user_names.max_by { |user_name| user_name.length }.length 
 # max_group_name = group_names.max_by { |group_name| group_name.length }.length 
 # max_file_size = file_sizes.max_by { |file_size| file_size.length }.length
 # max_timestamps = timestamps.max_by {|timestamp| timestamp.length }.length
  
 # hard_links_array = hard_links.map {|hard_link| hard_link.rjust(max_hard_link, ' ')}
 # user_names_array = user_names.map{|user_name| user_name.rjust(max_user_name, ' ')}
 # group_names_array = group_names.map{|group_name| group_name.rjust(max_group_name, ' ')}
 # file_sizes_array = file_sizes.map{ |file_size| file_size.rjust(max_file_size, ' ')}

  binding.irb

  # if options['r']
      
end

fetch_file_list

# print_file_list
