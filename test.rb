# frozen_string_literal: true

require 'json'

File.open('memo_data.json') do |file|
  @parser = JSON.parse(file.read)
end

puts @parser
