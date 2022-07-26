# memo.app

## Overview
Sinatraを利用して作成した簡単なメモアプリです｡
（フィヨルドブートキャンプの課題です）

## Usage
1. 実行に必要となるgemは以下の通りです｡
- `sinatra`
- `sinatra/reloader`
- `webrick`
- `pg`

2. 9行目の変数`db`にお使いのデータベース名を入力し保存してください｡

3. `make_save_file.sql`のsql文を実行してください｡

4. 以下のコマンドで起動します｡
`bundle install`
`bundle exec ruby memo_app.rb`

5. http://localhostg:4567 にアクセスし、メモアプリが利用できます｡
