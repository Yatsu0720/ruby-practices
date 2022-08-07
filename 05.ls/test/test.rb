#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'

COLUMN_COUNT = 3

FILE_TYPE_TABLE = {
  '01' => 'p',
  '02' => 'c',
  '04' => 'd',
  '06' => 'b',
  '10' => '-',
  '12' => 'l',
  '14' => 's'
}.freeze

PARMITION_TABLE = {
  '0' => '---',
  '1' => '--x',
  '2' => '-w-',
  '3' => '-wx',
  '4' => 'r--',
  '5' => 'r-x',
  '6' => 'rw-',
  '7' => 'rwx'
}.freeze

def main
  long_format_flag = false

  opts = OptionParser.new
  opts.on('-l') { long_format_flag = true }
  opts.parse!(ARGV)

  files = enumerate_files # ファイル名リスト
  return unless files

  if long_format_flag
    file_stats = build_file_stats(files)
    total_block_size = calculate_total_block_size(file_stats)
    l_option_output(total_block_size, file_stats)
  else
    basename_files = files.map { |file| File.basename(file) }
    padded_files = add_padding(basename_files)
    output(padded_files)
  end
end

def enumerate_files #ファイル名リストを取り出す
  if Dir.exist?(base_directory)
    Dir.glob("#{base_directory}*")
  else
    puts "ls: #{base_directory}: No such file or directory"
  end
end

def build_file_stats(files) #ハッシュを要素とした配列を作成
  files.map do |file| 
    stat = File.symlink?(file) ? File.lstat(file) : File.stat(file)
    file_stats = {}
    file_stats[:mode] = generate_mode(stat)
    file_stats[:nlink] = stat.nlink
    file_stats[:uid] = Etc.getpwuid(stat.uid).name
    file_stats[:gid] = Etc.getgrgid(stat.gid).name
    file_stats[:size] = stat.size
    file_stats[:block] = stat.blocks
    file_stats[:mtime] = stat
    file_stats[:name] = File.basename(file)
    file_path = generate_file_path(file_stats[:name])
    file_stats[:symlink] = File.readlink(file_path) if File.symlink?(file_path)
    file_stats
    binding.irb
  end
end

def generate_mode(stat)
  mode_characters = generate_mode_characters(stat)
  mode_characters.each_value.inject do |mode, mode_character|
    mode + mode_character
  end
end

def generate_mode_characters(stat)
  mode_numbers = stat.mode.to_s(8).rjust(6, '0').split(//)
  file_type = FILE_TYPE_TABLE[mode_numbers[0..1].join]
  owner_parmition = PARMITION_TABLE[mode_numbers[3]].dup
  group_parmition = PARMITION_TABLE[mode_numbers[4]].dup
  other_parmition = PARMITION_TABLE[mode_numbers[5]].dup
  owner_parmition[-1] = owner_parmition[-1] == 'x' ? 's' : 'S' if mode_numbers[2] == '4'
  group_parmition[-1] = group_parmition[-1] == 'x' ? 's' : 'S' if mode_numbers[2] == '2'
  other_parmition[-1] = other_parmition[-1] == 'x' ? 't' : 'T' if mode_numbers[2] == '1'
  { file_type: file_type, owner_parmition: owner_parmition, group_parmitio: group_parmition, other_parmition: other_parmition }
end

def calculate_total_block_size(file_stats)
  file_stats.sum do |file_stat|
    file_path = generate_file_path(file_stat[:name])
    File.file?(file_path) && !File.symlink?(file_path) ? file_stat[:block] : 0
  end
end

def base_directory #対象とするディレクトリを出す
  @base_directory ||= ARGV[0] || './'
end

def generate_file_path(file_name)
  "#{base_directory}#{file_name}"
end

def l_option_output(total_block_size, file_stats)
  nlink_padding, uid_paddinng, gid_paddinng = calculate_padding_size(file_stats)
  puts "total #{total_block_size}"
  file_stats.each do |file_stat|
    print file_stat[:mode].to_s.ljust(10)
    print file_stat[:nlink].to_s.rjust(nlink_padding)
    print file_stat[:uid].to_s.rjust(uid_paddinng)
    print file_stat[:gid].to_s.rjust(gid_paddinng)
    print file_stat[:size].to_s.rjust(6)
    print file_stat[:mtime].mtime.strftime(' %_m %e %H:%M').to_s
    print " #{file_stat[:name]}"
    print " -> #{file_stat[:symlink]}" if file_stat[:symlink]
    puts
  end
end

def calculate_padding_size(file_stats)
  nlink_sizes = []
  uid_sizes = []
  gid_sizes = []
  file_stats.each do |file_stat|
    nlink_sizes << file_stat[:nlink].to_s.size
    uid_sizes << file_stat[:uid].to_s.size
    gid_sizes << file_stat[:gid].to_s.size
  end
  nlink_padding = nlink_sizes.max + 2
  uid_paddinng = uid_sizes.max + 1
  gid_paddinng = gid_sizes.max + 2
  [nlink_padding, uid_paddinng, gid_paddinng]
end

def add_padding(basename_files)
  longgest_name = basename_files.max_by(&:size)
  padding = longgest_name.size + 3
  basename_files.map { |file| file.ljust(padding) }
end

def output(padded_files)
  row_count = (padded_files.size.to_f / COLUMN_COUNT).ceil
  sorted_files = Array.new(row_count) { [nil] }

  padded_files.each_with_index do |padded_file, index|
    row_index = index % row_count
    sorted_files[row_index] << padded_file
  end

  sorted_files.each do |sorted_file|
    joinned_file = sorted_file.join
    puts joinned_file unless joinned_file.empty?
  end
end

main
