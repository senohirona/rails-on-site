Railsアプリケーションで比較的よくある具体的な機能を実現するやり方を、taskleafアプリケーションへの機能追加という形で紹介していく

# 7-1 登録や編集の実行前に確認画面を挟む
「タスクを新規登録する際に確認画面を表示する」というものを実装していく。

今回は、新規登録画面で「確認ボタン」を押すと確認画面に遷移する。確認画面で「登録」ボタンをクリックするとタスクがデータベースに登録され、一覧画面に遷移する。
また、確認画面で「戻る」ボタンをクリックすると新規登録画面に戻ることができるようにする。
新規登録画面と確認画面の間ではお互いの画面の保持するレコードデータを相手の画面にパラメータで受け渡すことにする。この間、レコードデータはデータベースには登録されない。

## 確認画面を表示するアクションを追加する
まずは、確認画面を表示するアクションをapp/controllers/tasks_controller.rbに追加する。
ここでは、confirm_newという名前で作ることにする。

 confirm_newアクションでは、新規登録画面から受け取ったパラメータをもとにタスクオブジェクトを作成して、@task というインスタンス変数に代入する。
 新規登録画面から送られた情報の検証を行い、問題があれば新規登録画面を検証エラーメッセージと共に表示する

次にルーティングを設定する。
確認画面は「よくあるCRUDのためのアクション」とはみなされていないため、resourcesで一括で作られるルーティングとは別に定義してやる必要がある。
そこで、保存前のリソース(new)の確認をするという意味を込めて/tasks/new/confirmというURLをconfirm_newアクションに対応付けることとする。

```
resources :tasks do
	post :confirm, action: :confirm_new, on: :new
end
```

rails routesを実行すると、以下のようなルーティングが追加されたことを確認できる

```
confirm_new_task POST   /tasks/new/confirm(.:format)                                                             tasks#confirm_new
```

最後にビューを作成する。
app/views/tasks/confirm_new.html.slim を新しく作成する

管理画面では、createアクションに対して登録内容をパラメータで送るためにformを利用するが、このformはユーザーから見えない形で決まった値を贈りたいのでhidden_fieldを利用する。submitボタンを2つ置いているのは、新規画面に戻る用と登録用。

## 新規登録画面からの遷移先を変える
これまでは、新規登録画面には登録ボタンがあり、押すとcreateアクションへ遷移していた。これを、確認ボタンが合って、押すとconfirm_newアクションへ遷移するように変更する。

## 登録アクションで「戻る」ボタンからの遷移に対応する
確認画面の追加によって今までとは状況が少し変わる。

- confirm_newアクションでも検証をしているので、検証エラーがおこなる可能性は減る。しかし皆無ではないので、createアクションでも検証はしたほうが良い。検証エラーがあった場合、新規登録画面へ戻す。結果的に検証についてはコードを変更しなくて良い。
- 確認画面から「登録」が押されて遷移した場合は従来どおりの機能で良いが、「戻る」が押された場合には、戻る処理を提供する必要がある。

校舎の機能を実現するには、確認画面で「登録」「戻る」のどちらのボタンがクリックされたのかを判断する必要がある。
form要素内のsubmitボタンが押されると、パラメータに押されたボタンのname属性の値をキーとしてキャプションが格納される。
confirm_new.html.slimでは、戻るボタンには'back'という名前を与えているため、戻るボタンが押されたときは、params[:back]で"戻る"という文字列を得られる。
一方、'commit'という名前を与えている登録ボタンが押されたときは、params[:commit]で"登録"という文字列を得られる。

戻る機能を追加するために、createアクションを修正する。
「戻る」ボタンが押された場合は、現在のタスクの内容を引き継いだ状態で新規登録のフォーム画面を表示する。
それ以外の場合は、受け取ったパラメータをもとにタスクを登録して一覧画面に遷移する。


```
# 「戻る」ボタンが押された場合は、現在のタスクの内容を引き継いだ状態で新規登録のフォーム画面を表示する
if params[:back].present?
	# 新規登録フォームの画面を表示する処理はここで定義している
	render :new
	return
end
```

# 7-2 一覧画面に検索機能を追加する
タスク一覧のような一覧画面だけでは、扱うデータの件数が増えてくると不便になる。
ここでは、一覧画面に検索機能を追加する方法を解説する、
今回は、検索機能の実装時に利用されることの多いransackというgemを利用する

## 名称による検索
ransackをインストールすると、検索を行うためのransackメソッドがモデルに追加される。

tasks_controller.rb
```
def index
  @q = current_user.tasks.ransack(params[:q])
  @tasks = @q.result(distinct: true).recent
end
```

次にタスク一覧画面に検索フォームを実装する
「link_to'新規作成'」の間に、ransackの提供するヘルパーsearch_form_forを使って検索用のフォームを追加する。

```
= search_for @q, class: 'mb-5' do |f|
  .form-group.row
	= f.label :name_cont, '名称', class: 'col-sm-2 col-form-label'.col-sm-10
	  = f.search_field :name_cont, class: 'form-control'
  .form-group
	= f.submit class: 'btn btn-outline-primary'
```

ransackを利用する際は、検索フィールドの名前の一定のルールで命名する。
ここでは「名称に〇〇を含む」という検索を実装したいため、ビュー内の名称フィールド名を「name_cont」とした。


## 検索時のSQLの確認と検索マッチャー
検索時に実行されたSQLを、コンソールのログから確認してみる。

```
Task Load (0.4ms)  SELECT DISTINCT "tasks".* FROM "tasks" WHERE "tasks"."user_id" = $1 AND "tasks"."name" ILIKE '%ちびたん%' ORDER BY "tasks"."created_at" DESC
```

postgreSQLのILIKEが使われているのがわかる。
これは、先程検索フォームで「name_cont」という名前を指定したから。
_contをつけると、検索文字列を含むものを検索する。

## 登録日時による検索
登録日時による検索もできるようにする。
指定された日以降に登録されたタスクを検索可能にする。

```
  .form-group.row
	= f.label :created_at_gteq, '登録日時', class: 'col-sm-2 col-form-label'
	.col=sm-10
	  = f.search_field :created_at_gteq, class: 'form-control'
```

追加した登録日時フィールドでは、_gteqという検索マッチャーを利用している。
これは「該当の項目がフォームに入力した値と同じか、それより大きいこと」を条件にしたいときに使う。

コンソールログからSQLのみ抜粋

```
Task Load (0.3ms)  SELECT DISTINCT "tasks".* FROM "tasks" WHERE "tasks"."user_id" = $1 AND "tasks"."created_at" >= '2020-11-29 15:00:00' ORDER BY "tasks"."created_at" DESC
```

最後に単語と日時で検索した際のSQLを見てみる

```
Task Load (0.4ms)  SELECT DISTINCT "tasks".* FROM "tasks" WHERE "tasks"."user_id" = $1 AND ("tasks"."name" ILIKE '%ちびたん%' AND "tasks"."created_at" >= '2020-11-29 15:00:00') ORDER BY "tasks"."created_at" DESC
```

## 検索条件を絞る
今は名称と登録日時に関する検索しかできないが、実はユーザーが意図的にパラメータを加工すると、他のカラムを使った検索もできてしまう。
たとえばdescription_contというキーのパラメータを送れば、詳しい説明についての検索も行えてしまう。
そこで、ransackを利用する際は、検索に利用して良いカラムの範囲を制限しておくと良い。

Taskモデルに次のような実装を追加する
```
	def self.ransackable_attributes(auth_object = nil)
	  %w[name created_at]
	end

	def self.ransackable_associations(auth_object = nil)
	  []
	end
```

ransackable_attributesには、検索対象にすることを許可するカラムを指定する。
名称(name)と作成日時(created_at)を指定することで、それ以外のカラムについての検索条件がransackに渡されても無視されるようになる。
ransackable_associationsは検索条件煮含める関連を指定できる。このメソッドを空の配列を返すようにオーバーライドすることで、検索条件に意図しない関連を含めないようにすることができる。

# 7-3 一覧画面にソート機能を追加する
ユーザーが選んだ人気の項目でソートできるような機能を実装する。
具体的には、名称の降順と昇順をユーザーが指定してソートできるようにする。
ransackにはソートについてのヘルパーメソッドが用意されており、簡単にソート機能を実装できる。

まずはコントローラを変更する。
以前まではrecentスコープでソートをかけていたが、これを外す

tasks_controller.rb
```
  def index
	@q = current_user.tasks.ransack(params[:q])
	@tasks = @q.result(distinct: true)
  end
```

続いてビューを、ユーザーがソート方法を指定できるように変更する。

index.html.slim
```
.mb-3
table.table.table-hover
  thread.thread-default
	tr
	  th= sort_link(@q, :name)
	  th= Task.human_attribute_name(:created_at)
```

ransackの提供するsort_linkヘルパーを用いている。こうすることで、ソート操作ができる見出し部分を表示することができる。
sort_linkの第1引数にはコントローラでransackメソッドを呼び出して得られたRansack::Searchオブジェクト(ここでは@q)、第2引数にはソートを行う対象のカラム(ここでは「名称」を表す:name)を指定する。

# 7-5 ファイルをアップロードしてモデルに添付する
タスクへの画像ファイルが添付できるように機能を追加する。


## Active Storage
rails5.2からActive storageというファイル管理gemが同梱され、クラウドストレージサービス(S3, GCS 等)へファイルをアップロードして、データベース上でActiveRecordモデルに紐付けるということが簡単にできるようになった。

## Active Storageの準備
ActiveStorageをアプリケーションで使うための準備をする
以下コマンドを実行するとマイグレーションファイルが作成される。

```
$ bin/rails active_storage:install
Copied migration 20201225094128_create_active_storage_tables.active_storage.rb from active_storage
```

このマイグレーションは、ActiveStorageが利用する2つのテーブル、active_storage_blobsとactive_storage_attachmentsを作成する。
2つのモデルは、それぞれActiveStorage::BlobとActiveStorage::Attachementというモデルに紐付いている。

ActiveStorage::Blob : 添付されたファイルに対するモデル。ファイルの実態をデータベース外で管理することを前提としており、それ以外の情報、識別key、ファイル名、ファイルのメタデータ、サイズなどを管理する。

ActiveStorage::Attachement : ActiveStorage::Blobとアプリ内の様々なモデルを関連付ける中間テーブルに当たるモデル。一般的な多対多の中間テーブルに似ているが、アプリ内の様々なモデルと紐付けられるように、関連付けるモデルのクラス名や連携するFKカラム名をFK値とともに保持する。
一方、ActiveStorage::Blobとは直接的にidのみで紐付ける。

今回はTaskとActiveStorage::Blobを紐付けることになる。

先程生成されたマイグレーションファイルをDBに反映するため、migrateコマンドを実行する。

```
$ bin/rails db:migrate
== 20201225094128 CreateActiveStorageTables: migrating ========================
-- create_table(:active_storage_blobs, {})
   -> 0.0611s
-- create_table(:active_storage_attachments, {})
   -> 0.0150s
== 20201225094128 CreateActiveStorageTables: migrated (0.0763s) ===============
```

次に、添付したファイルの実体を管理する場所についての設定を行う。
設定はRails.application.config.active_storage.serviceにファイルを管理する場所の名前を与え、その名前に対する設定をconfig/storage.ymlに定義することで行う。

デフォルトでは、develop環境のファイル管理書はlocalとなっている。

```
  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local
```

次にこのlocalの設定が定義されているconfig/storage.ymlを見てみる。

```
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

localという設定はデフォルトで用意されているファイルの管理場所で、ローカル環境にファイルを格納する設定になっている。
今回はこの設定をそのまま利用する。

## タスクモデルに画像を添付できるようにする
まずはTaskモデルを編集する

```
class Task < ApplicationRecord
	has_one_attached :image
```

has_one_attachedというメソッドを使って、1つのタスクに1つの画像を紐付けること、その画像をTaskモデルからimageとして呼ぶことを指定している。

次にビューを編集する
登録前に確認画面を表示する機能を取り外す。
確認機能追加の際に追加したフォーム関係のコードを削除し、代わりに以前のようにformというパーシャルを利用するように変更する。

```
h1 タスクの新規登録

.nav.justify-content-end
  = link_to '一覧', tasks_path, class: 'nav-link'

= render partial: 'form', locals: {task: @task}
```

```
  .form-group
	= f.label :image
	= f.file_field :image, class: 'form-control'
  = f.submit nil, class: 'btn btn-primary'
```

次に画像が登録できるようにTasksControllerのtask_paramsメソッドを変更し、許可するパラメータのキーとして:image を追加する。

```
  def task_params
	params.require(:task).permit(:name, :description, :image)
  end
```

次に登録された画像を表示する機能を追加する。

```
	  td= auto_link(simple_format(h(@task.description), {}, sanitize: false, wrapper_tag: "div"))
	tr
	  th= Task.human_attribute_name(:image)
	  td= image_tag @task.image if @task.image.attached?
	tr
```


# 7-4 CSV形式のファイルのインポート/エクスポート
CSV出力機能はバックアップやExcel等の他のソフトウェアと連携のためにアプリケーション内のデータをCSV形式で出力する。
一方、CSV入力機能はCSV形式のファイルを読み込んでデータベースの登録・更新・削除等をおこなう。

今回はtaskleafにCSV出力機能とシンプルなCSV入力機能を実装してみる。

CSV形式のデータを扱うには、RubyのCSVライブラリを利用する。
config/application.rbでCSVをrequireしてアプリ内でCSVライブラリを使えるようにする。

## タスクをCSV出力する
まずは、taskleafのタスクデータをCSVファイルとして出力する機能を実施していく。
Taskモデルにto_csvというクラスメソッドを追加する。

task.rb
```
	def self.csv_attributes
	  ["name", "description", "created_at", "updated_at"]
	end

def self.generate_csv
      # CSV.generateを使ってCSVデータの文字列を生成する
      CSV.generate(headers: true) do |csv|
        # 変数csvにクラスメソッドcsv_attributesで定義した配列を格納する(<<... 配列に中身を追加)
        # CSVの1行目としてヘッダを出力する
        csv << csv_attributes
        all.each do |task|
          # allメソッドで全タスクを取得し、1レコード毎にCSVの1行を出力する
          csv << csv_attributes.map{|attr| task.send(attr)}
        end
      end
    end
```

1. CSVにどの属性をどの順番で出力するかをcsv_attributeというクラスメソッドから得られるように定義する。
2. CSV.generateを使ってCSVデータの文字列を生成する。生成した文字列がgenerate_csvクラスメソッドの戻り値となる。
3. CSVの1行目としてヘッダを出力する。ここでは1の属性名をそのまま見出しとして使っている。
4. allメソッドで全タスクを取得し、1レコード毎にCSVの1行を出力する。その際は、1の属性ごとにTaskオブジェクトから属性値を取り出してcsvに与える。

次にgenerate_csvクラスメソッドを呼び出すコントローラ側を実装する。
新しいアクションを作るのではなく「一覧表示のindexアクションに、異なるフォーマットでの出力機能を用意する」というふうに捉えてindexアクションに実装を加えることにする

```
respond_to do |format|
	format.html
	format.csv{send_data @tasks.generate_csv, filename: "tasks-#{Time.zone.now.strtfime('%Y%m%dS')}.csv"}
end
```

1. format.htmlはHTMLとしてアクセスされた場合(URLに拡張子なしでアクセスされた場合)、format.csvはCSVとしてアクセスされた場合(/tasks.csvというURLでアクセスされた場合)それぞれ実行される
2. HTMLフォーマットについては特に処理を指定しない。そのため、今まで通りデフォルトの動作としてindex.html.slimによって画面が表示される
3. CSVフォーマットの場合はsend_dataメソッドを使ってレスポンスを送り出し、送り出したデータを部サウザからファイルとしてダウンロードできるようにする。レスポンスの内容は先程のTask.generate_csvが生成するCSVデータとしている。ファイル名はダウンロードするたびに異なるファイル名になるように現在時刻を使って作成する。

※ respond_toメソッドはリクエストされるフォーマット(html, json等)によって処理を分けるメソッド

最後に出力機能への導線を追加する。
一覧画面の下部に「エクスポート」ボタンを設置し、ボタンが押されたらCSVファイルをダウンロードできるようにする

index.html.slim(末尾に追加)
```
= link_to 'エクスポート', tasks_path(format: :csv), class: 'btn btn-primary mb-3'
```

## CSVデータを入力する
一覧画面にインポート操作のUIを設け、そこからCSVファイルをアップロードしてCSVファイルの中身にそってデータベースにタスクを登録するようにする。

まずはTaskモデルにimportというクラスメソッドを作成する。

```
    def self.import(file)
      CSV.foreach(file.path, headers: true) do |row|
        task = new
        task.attributes = row.to_hash.slice(*csv_attributes)
        task.save!
      end
    end
```

1. fileという名前の引数でアップロードされたファイルの内容にアクセスするためのオブジェクトを受け取る
2. CSV.foreachを使って、CSVファイルを1行ずつ読み込む。headers: trueの指定により、1行目をヘッダとして無視するようにしている
3. CSV1行ごとに、Taskインスタンスを生成する(newはTask.newと同意)
4. 3で生成したTaskインスタンスの各属性に、CSVの1行の属性を加工して入れ込む
5. Taskインスタンスをデータベースに登録する

次にコントローラ側を実装する

tasks_controller.rb
```
def import
    current_user.tasks.import(params[:file])
    redirect_to tasks_url, notice: "タスクを追加した"
  end

```

1. 画面上のフィールドからアップロードされたファイルオブジェクトを引数に、関連越しに先程実装したimportメソッドを呼び出している。これにより、アップロードされたファイルの内容を、ログインしているユーザーのタスク軍として登録することができる
2. インポートが終わった後にタスク一覧画面に遷移する

次にimportアクションのためのルーティングを設定する。
以下を追加する。

routes.rb
```
post :import, on: :collection
```

最後にCSVファイルを指定してインポートを実行するUIを一覧画面に追加する。

追加用のCSVを用意し、インポートできるかを確認する。

# 7-7 ページネーション
ページネーション: レコード件数が一定数を超えた場合に複数のページに分割して表示を行うようにすること。

railsでページネーションを実現するために理容されているkaminariというgemを利用してタスク一覧画面でページネーションを実現する。

## kaminariのインストール

```
gem 'kaminari'
```

今回におけるコードの修正内容の要点
1. 表示するページの番号がparams[:page]でアクションに渡されるようにする
2. アクションでは、Taskデータを全件検索する代わりに、ページ番号(params[:page])に対応する範囲のデータを検索するするようにする
3. ビューでは、アクションから渡されたタスクデータを表示するのに加えて、現在どのページ・何件中何件を表示しているのかと言った情報や、他のページに移動するためのリンクを表示する

## ページ番号に対応する範囲のデータを検索するようにする
まずはタスク一覧画面のアクション、すなわちindexアクションを変更する
このアクションでは、ページ番号がparams[:page]として渡されてくることを前提とする。
ページ番号に対応するデータの範囲を検索するようにしたいが、実はこの検索の部分はkaminariが提供するpageスコープで簡単に行うことができる。

```
@tasks = @q.result(distinct: true).page(params[:page])
```

## ビューにページネーションのための情報を表示する
ビューにページネーションのを行う際に必要となる情報を表示するようにする

1. 現在どのページを表示しているのかの情報
2. 他のページに移動するためのリンク
3. 全データが何件なのかと言った情報

kaminariはこれらを表示するためのべんりなヘルパーメソッドを用意してくれており、1と2の目的のためにはpaginate、3の目的のためにはpage_entries_infoが利用できる

ちなみに、kaminariが内部で要している翻訳ファイルはenのみなので、jaの翻訳ファイルを用意する。

## 動作確認
ページネーションを確認するためには、一覧で表示するデータがそれなりの件数データベースに登録されている必要がある。
そこで、コンソールでデータを作るというやり方で100件ほどタスクを作成しておく。

```
irb(main):001:0> user = User.find(6)
100.times{ |i| user.tasks.create!(name: "サンプルタスク#{i}")}
```

## デザインの調整
もう少し見栄えを良くする。
pagenateヘルパーが表示に利用するパパーシャルテンプレートをアプリケーション内に用意し、それを自分でカスタマイズすることでデザインを調整することができる.

今回はbootstrap4というテーマのパパーシャルテンプレートを生成する

```
bin/rails g kaminari:views bootstrap4
```

生成が完了すると、ページに見栄えが変わっている。

# 7-8 非同期処理や定期実行を行う(Jobスケジューリング)
Active job: バックグラウンドで様々な処理を非同期に行うためのフレームワーク

## 非同期ツールの導入
Activejobは実際にバックグラウンドで非同期処理を行うツールそのものではなく、個別のツールを共通的なI/Fで扱うための仕組み。
そのため、非同期処理を行うにはそのためのツールを制定し、導入する必要がある。
今回は現場でよく利用されているSidekiqを使う

Sidekiqを利用するためにredisをインストールする

```
brew install redis
```

redisサーバをを起動する


```
redis-server
```

※起動後は別タブでターミナルを開いて作業する

次にsidekiqをインストールする
(ver を5.0にしないと今回やることが失敗するので今回はバージョンを固定する)

```
gem 'sidekiq','~> 5.0'
```

起動

```
bundle exec sidekiq
```

RailsとSidekiqを連携させるためにdevelopment.rbに追記をする

```
config.active_job.queue_adapter = :sidekiq
```

## ジョブの作成、実行
実際にジョブを作成していく。
ここでは、実質的な仕事をシない、動作確認用の簡単な例としてのジョブを作る。
まず、ジェネレータでジョブの雛形を作成する

```
$ bin/rails g job sample
Running via Spring preloader in process 94848
      invoke  test_unit
      create    test/jobs/sample_job_test.rb
      create  app/jobs/sample_job.rb
```

sample_job.rbというファイルが作成されるで、以下のように変更する。

```
  def perform(*args)
    Sidekiq::Logging.logger.info "サンプルジョブを実行しました"
  end
```

これでバックグラウンドで実行したい処理の中身を準備することができた。
次にRailsアプリケーションからこの処理をどうやって呼び出すのか見ていく。
具体的には、タスク作成を行ったあとで先程のジョブを呼び出すことにする。
タスクコントローラを以下のように変更する

```
if @task.save
      logger.debug "task: #{@task.attributes.inspect}"
      SampleJob.perform_later
      redirect_to @task, notice: "タスク「#{@task.name}」を登録しました。"
    else
```

変更箇所では、perform_laterというメソッドを用いて、先程作成したログ出力のジョブを非同期に実行させている。
ここで、perform_laterはジョブの実行を予約するだけで、ジョブの処理の開始や完了を待つことはない。
ジョブの処理は、もしもこの時点で非同期処理ツールが他のジョブの実行で忙しい等すぐに対応できない状態であれば、処理できる状態になった時点で開始される

動作を確認する
(ブラウザからタスクを登録すると、Sidekiqを起動しているターミナルには以下のようなログが出る)

```
2020-12-28T09:48:20.406Z 96209 TID-ow3s3ohg9 SampleJob JID-795cf41e948d87f06848e6ac INFO: start
2020-12-28T09:48:20.744Z 96209 TID-ow3s3ohg9 SampleJob JID-795cf41e948d87f06848e6ac INFO: サンプルジョブを実行しました
2020-12-28T09:48:20.744Z 96209 TID-ow3s3ohg9 SampleJob JID-795cf41e948d87f06848e6ac INFO: done: 0.338 sec
2020-12-28T09:48:42.777Z 96209 TID-ow3s3oi2d SampleJob JID-1022b0a929c54f86c4da4c8b INFO: start
2020-12-28T09:48:42.786Z 96209 TID-ow3s3oi2d SampleJob JID-1022b0a929c54f86c4da4c8b INFO: サンプルジョブを実行しました
2020-12-28T09:48:42.787Z 96209 TID-ow3s3oi2d SampleJob JID-1022b0a929c54f86c4da4c8b INFO: done: 0.009 sec
2020-12-28T09:49:52.763Z 96209 TID-ow3s3ohvd SampleJob JID-dd5739020e396cdca0f708c1 INFO: start
2020-12-28T09:49:52.772Z 96209 TID-ow3s3ohvd SampleJob JID-dd5739020e396cdca0f708c1 INFO: サンプルジョブを実行しました
2020-12-28T09:49:52.772Z 96209 TID-ow3s3ohvd SampleJob JID-dd5739020e396cdca0f708c1 INFO: done: 0.009 sec
```

## 実行日時指定
ジョブは日時を指定して実行予約することもできる。
次にようにsetメソッドを使うと、「翌日の正午に」ジョブを実行するようにできる。

```
SampleJob.set(wait_until: Date.tomorrow.noon).perform_later
```

Sidekiqでは、複数のジョブを並列で実行できる。その際、ジョブをどのような優先順位で実行するかをキューという仕組みを使って制御することができる。

