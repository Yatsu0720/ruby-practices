# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'webrick'
require 'net/http'

get '/' do
  @memo_title = params[:memo_title]
  @memo_text = params[:memo_text]
  @memo_id = params[:id]

  @json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  erb :index, layout: :layout
end

get '/new' do
  erb :new_memo
end

get '/memo' do
  erb :memo
end

get '/memo/:name' do
  @memo_id = params[:name]

  @json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  @memo_title = @json_data.fetch(@memo_id).keys[0]
  @memo_text = @json_data.fetch(@memo_id).fetch(@memo_title)

  erb :memo
end

get '/memo/:name/edit' do
  @memo_id = params[:name]

  json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  @json_data = json_data

  @memo_title = @json_data.fetch(@memo_id).keys[0]
  @memo_text = @json_data.fetch(@memo_id).fetch(@memo_title)

  erb :edit
end

post '/' do
  @memo_title = h(params[:memo_title]).to_s
  @memo_text = h(params[:memo_text]).to_s
  @memo_id = h(params[:id]).to_s

  @json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  value = { @memo_title => @memo_text }
  @json_data[@memo_id] = value

  File.open('memo_data.json', 'w') do |file|
    JSON.dump(@json_data, file)
  end

  erb :index
end

patch '/memo/:name/edit' do
  @memo_id = params[:name]

  @memo_title = h(params[:memo_title]).to_s
  @memo_text = h(params[:memo_text]).to_s

  @json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  @json_data[@memo_id] = { @memo_title => @memo_text }

  File.open('memo_data.json', 'w') do |file|
    JSON.dump(@json_data, file)
  end

  redirect "/memo/#{@memo_id}"

  erb :edit
end

delete '/memo/:name' do
  @memo_id = params[:name]

  json_data = File.open('memo_data.json') do |file|
    JSON.parse(file.read)
  end

  json_data.delete(@memo_id)

  @json_data = json_data

  open('memo_data.json', 'w') do |file|
    JSON.dump(json_data, file)
  end

  redirect '/'

  erb :index
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

error do
  erb :notfound
end
