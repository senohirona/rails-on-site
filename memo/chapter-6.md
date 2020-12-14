# 6-1 Railsを取り巻く世界

RailsはRubyを始め様々な技術を使って組み上げられている。

## 影響を与えたアイデア
MVC
オブジェクト指向
自動テスト
RESTful

## Railsと関連技術
Docker
CI
Lint
Capistorano
RSpec
JQuery
Vue.js
React
webpack
Slim

Rails
RDB
Webサーバ
webpacker
ERB

Ruby
RubyGems
minitest

Bundker
Git

## Web
HTTP
ブラウザ
HTML
Javascript

## 関心事
開発
開発環境
デプロイ
運用

この章では、特に以下のことについて解説していく
## アイデア
RESTful

## 関心事
開発
    ルーティングの詳細
    国際化
    時刻の扱い方
    エラー処理のカスタマイズ
    セキュリティ
開発環境
    アセットパイプライン
デプロイ・運用
    production 環境


# 6-2 ルーティング
ルーティング: サクセスを受けて適切なアクションへと案内する仕組み
Railsのルーティングは少し複雑だが、これには理由があり、2つの本質的に異なる構造間のれん系という仕事を担っているから。

1. URLやHTTPメソッドで表現するインターフェイスとしての構造
2. Rubyのプログラミング上の合理性で構造化したコントローラ・アクションの構造

RailsのルーティングはRESTfulなインターフェイスを作りやすいように作られているが、RESTfulであるかどうかに関わらずどのようなデザインのインターフェイスも実現することができる基本機能を備えている。

まずはじめにconfig/routes.rbで定義する最小単位（ルートと呼ぶ)について説明する。


## ルートを構成する5つの要素
ルーティングはリクエストをアクションへと道案内するルートの集合として捉えることができる。
まず、ルートを構成する主な要素を理解する

|要素の名前|要素の内容の例||
--|--|--
|HTTPメソッド|GET,POST, PATCH|サーバへのリクエストの際に使用する。情報の送信・取得の方法を表す。一般的なブラウザから送ることができるのはGETとPOST飲みだが、Railsでは_methodというリクエストパラメータの値に"PATCH","DELETE"という文字列が入ったPOSTリクエストを、それぞれPATCH,DELETEリクエストと解釈する|
|URLパターン|/task,/tasks/:id|URLそのものや、:idのように一部の任意の文字が入るようなパターンを指定する|
|URLパターンの名前|new_taks,task|定義したURLパターン毎に一意な名前をつける。この名前をもとに、対応するURLを生成するためのnew_task_path_task_urlと言ったヘルパーメソッドが用意される|
|コントローラ|tasks(TasksConttoller)|呼び出したいアクションのコントローラクラスを指定する|
|アクション|index|呼び出したいアクションを指定する|

要素がどのように利用されるかを表したのが次の図
この図で注目してほしいのは矢印が2つある点
１. HTTPメソッドとしてURLからアクションに案内するための定義
2. URLパターンに名前をつけておいて、その名前をもとにURLをかんたんに生成するためのヘルパーメソッドを作り出す

HTTPメソッド  URLパターン       コントローラ        アクション
|GET|       |/task|   1  ->  |TasksController| |index|
    URLパターン名 ↓             URLヘルパーメソッド
            |tasks|   2  ->  |tasks_path|


## 1つのルートを定義する
前述のような5つの要素を持ち、アクションへの案内とURLヘルパーメソッドの生成の2つの働きをする、1つのルートを定義してみる。

routes.rbに定義されている以下の定義を見てみる

```
get '/login', to: 'sessions#new'
```

この定義は次のようになる

```
GETメソッドで`/login`というURLに対してリクエストが来たら、SessionsControllerのnewというアクションを呼び出してほしい。また、`/login`というURLを、login_pathというヘルパーメソッドで生成できるようにする
```

別の定義も見てみる

```
  post '/login', to: 'sessions#create'
```

この定義は次のように鳴る

```
POSTメソッドで`/login`というURLでリクエストされたときにSessionsControllerのcreateというアクションを呼び出してほしい。URLパターン名は先の定義と同じくloginとする
```

複数のルートのURLパターンが同じ場合は、基本的に同じURLパターン名をつけて、同じURLヘルパーメソッドを利用することが多くなっている。
URLパターン名はルート毎というよりも、URLパターンごとにつけるものだと理解しておくと良い。

|GET|       |/login|   1  ->  |SessionsController| |new|
    URLパターン名 ↓             URLヘルパーメソッド
            |login|   2  ->  |login _path|
                ↑
|POST|      |/login|     ->  |SessionsController| |create|

routes.rbの定義がどの様になっているかは、rails routesというコマンドで確認することができる

```
$ bin/rails routes                                                                                                                                                                                                  Prefix Verb   URI Pattern                                                                              Controller#Action                                login GET    /login(.:format)                                                                         sessions#new                                      POST   /login(.:format)                                                                         sessions#create                               logout DELETE /logout(.:format)                                                                        sessions#destroy
                         sessions_new GET    /sessions/new(.:format)                                                                  sessions#new
```


ここではgetとpostの例を上げたが、他にもpatch,put, deleteの各HTTPメソッドに対応するていぎが可能。
get等の代わりにmatchと:viaオプションの組み合わせを使うと、複数のHTTPメソッドを受け付ける1つのルートを定義できる。
例えば、もしも前述のsessions#createを、POSTのときだけでなくPATCHやPUTでリクエストされた際にも呼びたいのであれば次のように記述すれば可能

```
match `/login`, to: 'sessions#create', via: [:post,:patch,:put]
```

## 「RESTful」の概要を掴んでおく

RESTful: REST(REspresentational State Transfer)という設計原則に従うシステムのことを指す形容詞

### RESTの設計原則
1. HTTPリクエストはそのリクエストで必要な情報をすべて持ち、前のリクエストからの状態の保存されている必要がない(ステートレス)
2. 個々の情報(リソース)への「操作」の表現がHTTPメソッドとして統一されている
3. 個々の情報がそれぞれ一意なURI(URLより広い概念の用語でURLも含む)で表されている
4. ある情報から別の情報を参照したいときは、リンクを利用する

RailsはアプリケーションをRESTfulなシステムとして開発しやすくする機能を提供している。
ここでは次のような特徴があると理解しておく
- URLが表す情報のことをリソースと呼ぶ
- 上記2つの理由により、Railsでは一般的なブラウザのサポートするGET/POSTの2種類だけでなく、PATCH、PUT、DELETEといったHTTPメソッドをサポートする
- 上記2つの理由により、RESTfulなシステムでは、操作はHTTPメソッドで表現するものであり、URLで表現するものではない。そのため、URLはなるべく情報（リソース)名前を表す形、すなわち「名詞」にするという発送で作られている

## RESTfulにするためのRailsの定義
RailsにおいてRESTfulなインターフェイスとはどういったものなのか

まずは参照について考えてみる。
参照: 「リソースの〇〇を取得したいです」というようなリクエスト
「取得したい」というのが操作、「リソース〇〇」が操作の対象となる。取得操作を表すHTTPメソッドは、英語的にも同じ意味合いとなるGET。
そのため、タスクの一覧を参照したいのであれば、英語の語順で言えば「GETタスク達」ということになり、「GET/tasks」というインターフェイスが良いということになる。
特定の1つのリソースを参照したいなら「GET17番のタスク」と言ったことになるので、「GET/task/17」が適切だということになる。

次に、登録の実行(createアクション)はどうだろうか。
登録する時点では、登録する予定のリソースはまだ世界に存在しない。そこで、登録後に所属することになる"親"に当たるリソースに対して、新しい情報を送るイメージになる。
そこで「POSTタスク達」という感じで「POST/tasks」に実現する

こんな調子で、CRUDを実現するための他のよくあるアクションについても、RESTfulな設計パターンを考えることができる。そのような設計パターンをもとに、よくあるCRUDのアクションのルーティングを一括で登録できるようにしてくれるのが、次に説明するresourcesという機能。

## resourcesでCRUDのルート一式を定義する
3章ではタスク管理のルーティング定義を以下のようにしていた。

```
resources :tasks
```

Railsでは、一覧・詳細・登録・更新・削除というよくある機能群を提供するために必要となるルート一式を、resourcesというメソッドを使って定義することができる。
ドノようなルートがまとめて定義されるかを、先に上げたresource :tasksの例をもとに見ていく。なおこの場合、全てのルートにおいて、コントローラはTasksControllerになる。

|機能|HTTPメソッド|URLパターン|URLパターン名|ヘルパーメソッド|アクション|
--|--|--|--|--|--
|一覧|GET|/tasks|tasks|tasks_path|index|
|詳細|GET|/tasks/:id|task|task|task_path|show|
|新規登録画面|GET|/tasks/new|new_task|new_task_path|new|
|登録|POST|/tasks|tasks|tasks_path|crete|
|編集画面|GET|/task/:id/edit|edit_task|edit_task_path|update|
|更新|PATCHまたはPUT|/tasks/:id|task|task_path|update|
|削除|DELETE|/tasks/:id|task|task_path|destroy|

resourcesに似た機能として、対象リソースが1つしか存在しないケースのためのresourceという定義方法もある。例えば、システム共通の設定をリソースで表すとするならば、そのような設定はアプリケーション内に1つしか存在しない。
resourceを使うと、リソースが1つしか無いため識別の必要がなくなり、URL内でidを使わなくなる。また、リソースを見る機能としては詳細があれば十分なので、indexアクションを用意しない。

## routes.rbの構造化
get, post, matchあるいはresourcesなど、ルートを定義する記述は、前提となるURL階層やコントロールクラスを修飾するモジュール、コントロールクラス。URLパターン名のプリフィックスなどで構造化することができる。

構造化のためのメソッドの例

- scope: URL階層(:path)、モジュール(:module)、URLパターン名のプリフィックス(:as)などをオプションに指定することで、ブロック内の定義にまとめて一定の制約をかける。
- namespace: URL階層、モジュール、URLパターン名に一括で一定の制約をかける。scopeと違って一括なので、URL階層だけに制約をかけるううと言ったことはできない。
- controller: コントローラを指定する

# 6-3 国際化
国際化: 様々な国ごとに最適な表示などを行えるように基盤を整えること

今回作成したアプリでは日本語化のために以下のことを行った
- config.i18n.default_locale = :jaを設定する
- エラーメッセージの日本語データの書かれたja.ymlを入手する
- ja.ymlにモデルのクラスや属性に対応する日本語を記述する

これらは、Railsの用意している国際化の仕組みに則ってアプリケーションの文字列を日本向けにローカライズしていることに相応する。

ここでは、文字列表現についてローカライズしたり、複数の言語を切り替えて利用するための方法について説明する。
把握しておくべきステップは以下の3つ

1. 利用するロケールに対応する翻訳データのymlファイルをconfig/localsの下に配置する。
2. 「現在のロケール」を示すI18n.localeが正しく設定された状態にする。
    - locale.rb等の中で、デフォルト値であるconfig.i18n.default_localeを適切に設定する
    - 複数の言語を切り替えて利用したい場合は、アプリケーションのフィルタなどで、リクエストごとにI18n.localeの値を変更する
3. 目的の翻訳データを利用する。基本的にI18n.localeに設定されたロケールの翻訳データが使われるが、個別にロケールを指定することもできる

## ユーザー毎に言語を切り替える
仮に、ユーザー毎に私用言語を設定してDBに保存するとする。Userクラスのlocaleという属性に`jp`もしくは`en`を入れるものとする。
ログインしているユーザーをcurrent_userで取得できるとすれば、次のファイルのようにリクエストごとにI18n.localeの値を切り替えることができる。

コントローラファイル
```
def set_locale
  I18n.locale = current_user&.locale || :ja # ログインしていなければ日本語
end

```

## 翻訳ファイルの扱い方
エラーメッセージやモデルのクラス名・属性をja.ymlに設定したが、翻訳ファイルにはこのほか、以下のような設定ができる

- (ActibeRecodeベースではない)ActiveModelベースのモデルの翻訳情報
- localizeメソッドによって得られる日や日時の文字列表現
- よくあるボタンのキャプションなど、Railsが内部的に利用する文字列
- そのほか、任意の階層に任意のデータを定義できる

ymlファイルは、末尾に[ロケール名].ymlがつくにんいの名前にすることができる。config/locals以下のファイルは全て読まれるので、複数のファイルに分割して整理することができる。例えば、モデル系だけをわけたければ、models.ja.ymlなどとすることもできる

翻訳情報の取得方法についても見ていく。アプリ作成時はモデルのクラス名の翻訳をTask.model_name.humanで、属性名の翻訳をTask.human_attribute_name(:name)のような方法で取得していたが、より汎用的に翻訳情報を取るにはI18n.tというメソッドにを使う。
例えば、次のような階層の翻訳情報があるとする

```
ja:
  taskleaf:
    page:
      titles:
        tasks: "タスク一覧"
```

このとき、現在のロケールが:jaの状態でI18n,t("taskleaf.page.titles.tasks")を実行すると"タスク一覧"を得ることができる。
I18n.t("taskleaf.page.titles")とすればtitles以下の設定を{tasks: "タスク一覧"}というようなハッシュオブジェクトで得ることができる。


# 6-4 日時の扱い方
Railsでは、日時のデータをタイムゾーンとともに取り扱うことができるようになっている。

タイムゾーンとともに日時を扱うには、Timeの代わりにActiveSupport::TimeWithZoneクラスを用いる。
Railsが日時を扱う際には、自動的にこのクラスが利用される。

## 日時の扱い方に関する設定
Railsでは、モデルオブジェクトの抱えるcreated_at等の日時オブジェクトはActiveSupport::TimeWithZoneオブジェクトとなるが、これに関して次の2店を設定することができる。

1. どのタイムゾーンの表現で日時をDBに保存し、読み出し時に同解釈するか
2. 1に基づいて取り出した日時データを、どのタイムゾーンのTimeWithZoneオブジェクトとして生成するか。また、ユーザーの入力などに由来する日時データをモデルに代入する際、どのタイムゾーンの時刻であると解釈し、どのタイムゾーンのTimeWithZoneオブジェクトとして生成するか

1については、config/application.rb等でconfig.active_record.default_timezoneに設定する。:utcまたは:localの2種類のみを設定できる。つまり、Railsでは日時をデータベースに入れる際は、UTC時間で入れるか、Rubyの動作している環境のシステム時刻で入れるかのどちらかを選ぶことになる。デフォルトは:utcとなっている。

どちらを選んでも、アプリケーション内での挙動には違いはなく、DBに実際に入る時刻表現が変わってくることになる。

||メリット|
--|--
|:utc|システムのタイムゾーンを気にしなくて済み、運用環境への依存が少ない。Railsのデフォルトなので、エンジニアにとって扱いやすい|
|:local|DBデータとしてはこちらのほうが直感的で扱いやすい場合がある|


2については、最終的に時刻をTimeWithZoneオブジェクトにする際に、どのタイムゾーンのオブジェクトにするかを、Time.zoneの値を制御することで設定できる。
Time.zoneの値の制御の仕方は以下の様に分類できる。

A. アプリケーション起動時に適切な値にする
B. Railsアプリケーションの中で動的にTime.zoneを変更する

Aの、起動時のTime.zoneはconfig/application.rbでconfig.time_zoneに設定する。たとえば、主に日本で利用する想定のアプリケーションならば、config.time_zoneに'Asia/Tokyo'を設定しておくのが便利。

## taskleafアプリケーションのデフォルトのタイムゾーンを日本時間にする
試しに、taskleafアプリケーションのデフォルトのタイムゾーンをデフォルトのUTCから日本時間に変更してみる

application.rbに以下を追加する

```
config.time_zone = 'Asia/Tokyo'
```

## Time.currentやData.currentを利用する
現在時刻のActiveSupport：：TimeWithZoneオブジェクトを取得する方法としてTime.zone.nowを紹介したが、Time.currentでも同じ結果を得ることができる
