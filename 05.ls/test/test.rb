require "optparse"

opts = OptionParser.new
opts.on("-l")
p ARGV
p opts.parse!(ARGV) || '.'
p ARGV[0] || '.'

binding.irb
