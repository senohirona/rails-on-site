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
