# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'webrick'
require 'pg'

db = 'memos'

conn = PG.connect(dbname: db)

get '/memos' do
  conn.exec('SELECT * FROM memo_data') do |result|
    @memos = result.map do |row|
      row
    end
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

  conn.exec('SELECT * FROM memo_data WHERE memo_id = $1', [@memo_id.to_s]) do |result|
    @memos = result.map { |row| row }
  end
  @memo_title = @memos[0]['memo_title']
  @memo_body = @memos[0]['memo_body']

  @title = @memo_title

  erb :memo
end

get '/memos/:id/edit' do
  @memo_id = params[:id]

  conn.exec('SELECT * FROM memo_data WHERE memo_id = $1', [@memo_id.to_s]) do |result|
    @memos = result.map { |row| row }
  end

  @memo_title = @memos[0]['memo_title']
  @memo_body = @memos[0]['memo_body']

  @title = "Edit:#{@memo_title}"

  erb :edit
end

post '/memos' do
  @memo_title = h(params[:memo_title]).to_s
  @memo_body = h(params[:memo_body]).to_s
  @memo_id = h(params[:id]).to_s

  conn.exec("INSERT INTO memo_data (memo_title, memo_body, memo_id)  VALUES ( '#{@memo_title}', '#{@memo_body}', '#{@memo_id}')")

  redirect '/memos'
end

patch '/memos/:id' do
  @memo_id = h(params[:id])
  @memo_title = h(params[:memo_title]).to_s
  @memo_body = h(params[:memo_body]).to_s

  conn.exec_params(
    'UPDATE memo_data SET memo_title = $1, memo_body = $2 WHERE memo_id = $3', [@memo_title.to_s, @memo_body.to_s, @memo_id.to_s]
  )

  redirect "/memos/#{@memo_id}"
end

delete '/memos/:id' do
  @memo_id = params[:id]

  conn.exec('DELETE FROM memo_data WHERE memo_id = $1', [@memo_id.to_s]) do |result|
    @memos = result.map { |row| row }
  end

  redirect '/memos'
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

error do
  erb :notfound
end
