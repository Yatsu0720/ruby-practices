# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'webrick'
require 'net/http'

MEMO_DATA = 'memo_data.json'

get '/memos' do
  @json_data = File.open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  @title = 'メモアプリ'

  erb :index, layout: :layout
end

get '/memos/new' do
  @title = '新規登録'

  erb :new_memo
end

get '/memos/:id' do
  @memo_id = params[:id]

  @json_data = File.open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  @memo = @json_data[@memo_id]
  @memo_title = @memo["title"]
  @memo_body = @memo["body"]

  @title = @memo_title

  @memo = @json_data[@memo_id]
  @memo_title = @memo["title"]
  @memo_body = @memo["body"]

  erb :memo
end

get '/memos/:id/edit' do
  @memo_id = params[:id]

  @json_data = open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  @memo = @json_data[@memo_id]
  @memo_title = @memo["title"]
  @memo_body = @memo["body"]

  @title = "Edit:" + @memo_title 
    
  erb :edit
end

post '/memos' do
  @memo_title = h(params[:memo_title]).to_s
  @memo_body = h(params[:memo_body]).to_s
  @memo_id = h(params[:id]).to_s

  @json_data = File.open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  @json_data[@memo_id] = { "title" => @memo_title, "body" => @memo_body }

  File.open(MEMO_DATA, 'w') do |file|
    JSON.dump(@json_data, file)
  end

  erb :index
end

patch '/memos/:id' do
  @memo_id = h(params[:id])
  @memo_title = h(params[:memo_title]).to_s
  @memo_body = h(params[:memo_body]).to_s
  
  @json_data = File.open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  @json_data[@memo_id] = { "title" => @memo_title, "body" => @memo_body }

  File.open(MEMO_DATA, 'w') do |file|
    JSON.dump(@json_data, file)
  end

  redirect "/memos/#{@memo_id}"

  erb :edit
end

delete '/memos/:id' do
  @memo_id = params[:id]

  json_data = File.open(MEMO_DATA) do |file|
    JSON.parse(file.read)
  end

  json_data.delete(@memo_id)

  @json_data = json_data

  open(MEMO_DATA, 'w') do |file|
    JSON.dump(json_data, file)
  end

  redirect '/memos'

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
