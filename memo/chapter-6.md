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


# 6-5 エラー処理のカスタマイズについて

## Railsのエラー処理の概要


# 6-6 Railsのログ

## ログの利用方法
アプリケーションログはターミナルの他にlog/development.logに出力される。
これは環境により異なり、production環境で動かしていればlog/production.logに出力される。

## 自分でログを出力する
Railsが自動的に出力するログ以外にも、自分でコントローラやモデルなどからログを出力することができる。
ログ出力は、Railsが用意しているloggerオブジェクトを通じて行う。

例えば、デバッグ用にタスク作成時に保存したタスクの情報をログ出力させたい場合、次のように記載する

```
logger.debug "task: #{@task.attributes.inspec}"
```

そして、サーバーを立ち上げてタスクを新しく作成すると、ターミナルに以下のようなログが出力される

```
task: {"id"=>nil, "name"=>"ちびたんの写真を撮る", "description"=>"撮るのじゃ(｀・ω・´)ｼｬｷｰﾝ", "created_at"=>nil, "updated_at"=>nil, "user_id"=>6}
```


## ログレベル
ログはログレベルごとにメソッドが違う。
環境ごとに、どのログレベルまで出力するかを設定することができる。

|ログレベル(数字)|ログレベル|意味|
--|--|--
|5|unknown|原因不明のエラー|
|4|fatal|エラーハンドリング不可能な致命的エラー|
|3|error|エラーハンドリング可能なエラー|
|2|warn|警告|
|1|info|通知|
|0|debug|開発者向けデバッグ用詳細情報|

## ログ(ロガー)の設定
### ログレベルの設定
ログレベルの設定は、config/environments/development.rbに、config.log_level = :warnを追記する。
こうすると、warn以上のログのみを出力することができる。

### アプリケーションログの特定のパラメータ値をマスクする。
ログにはパスワードやカード情報など、セキュアな情報が含まれる場合、意図せず出力されてしまう可能性がある。
ログに出力したくないパラメータをfillter_parameter_logging.rbのRails.applivarion.config.filter_parametersに設定すると、特定のパラメータの値を隠してログを出力することができる。

例(この設定では、デフォルトでpasswordが設定されている)
```
Rails.application.config.filter_parameters += [:password]
```

# 6-7 セキュリティを強化する
Railsには標準でセキュリティを高めるための機能が備わっており、意識しなくてもある程度安全なwebアプリケーションを作ることができる。
ここではRailsの代表的なセキュリティ関連の機能として以下3つを解説する

- Strong Prameters
- CSRF対策
- 各所のインジェクション対策


## 意図しないパラメータを弾く「Strong Parameters」
コントローラでリクエストパラメータを受け取る際に、想定通りのパラメータかどうかをホワイトリスト方式でチェックする機能が「Strong Parameters」。

モデルの便利な機能に、複数の属性を一括で代入することができる、マスアサインメント機能がある。例えば、次のようなコードは新たにTaskオブジェクトを生成する際に、nameとdescriptionという2つの属性に一括で代入している。

```
> task = Task.new(name: 'ラーメン食べたい', description: '今すぐ食べたい')
```

もし、この機能がなければ次のように書かなければならない

```
> task = Task.new
> task.name = 'ラーメン食べたい'
> task.description = '今すぐ食べたい'
```

マスアサインメント機能おかげで、コントローラで受け取ったパラメータの一部を次のように直接モデルに渡して、複数の属性値を一括で割り当てることができる。

```
> task = Task.new(params[:task])
```

とても便利だが、もし、パラメータに意図せぬ属性が紛れ込んでいた場合、想定外の属性についても登録・更新が行えてしまうという問題が生じてしまう。

例えば、Taskにはspecialというフラグがあって、その値がtrueのときはタスクを目立たせることができるとする。
ただし、このフラグをtrueにすることができるのは、有料ユーザーがタスクを登録・編集しているときだけとする。
このような場合、有料ユーザーでなくても、サーバに送るリクエスト・パラメータを加工して、specialフラグがtrueになるようなリクエストを送ることが技術的には可能。このようなことをされてしまうと、お金を払わずに有料ユーザー限定の機能を使われてしまうということがある。

これを防ぐには、パラメータのどの属性を許可してどの属性を弾くのかを制御する必要がある。
このときに利用できるのがStrong Parametersという機能。
先程のspecialフラグであれば、userが有料ユーザー(premium?=true なユーザー)かどうかで、許可する属性の顔ぶれを変更してやる。
パラメータを扱うのはコントローラの役割なので、このような記述は基本的にコントローラに記述する。

```
# ユーザーがpremium会員かを判定する
task_params = if user.premium?
  params.require(:task).permit(:name, :description, :special)
else
    # ↓paramsには:taskがあるよね?なければ例外を出して
  params.require(:task).permit(:name, :description)
                        # ↑そのparams[:task]から取り出していいのは、:nameと:descriptionだけ。とは無視して。情報が足りなくても構わない。
end

Task.new(task_params)
```

これで、一般ユーザーからのリクエストにspecialフラグが混ざっていても、params[:task]にアクセスした際にspecialフラグに関する属性は入ってこない状況になる。つまり、許可しない属性情報を無視することができる。なお、permitで指定した属性が送られてこなくても、例外を出したりはしない。

この他、上記のコードではrequireメソッドの挙動として、もしもparams[:task]自体が送られてきていなければ、想定したパラメータが送られてきていない、という例外が発生する。

## CSRF対策を利用する
CSRF(cross-site request forgery)は、別のwebサイト上に用意したコンテンツのリンクを踏んだり、画像を表示したりしたことをきっかけに、ユーザーがログインしているwebアプリケーションに悪意ある操作を行う攻撃。
リクエストを偽装(forgery)する特徴からCSRFと呼ばれる。

webアプリケーションでは、ユーザーのデータの削除と言った重大な操作は、ユーザー本人にしかできないと言った作りになっていることが多い。
このとき、アクセスしてきているのがユーザー本人であるかどうかは、Railsアプリケーションの場合、cookieを利用したセッションの状態で判断するのが基本となる。

ブラウザがcookieを送信する対象はcookieうぃ発行したホストのみに限定される。したがって悪意ある別のサイトはこのcookieを受け取ることができない。
しかし、ユーザーの意図しない「アプリケーションへのリクエスト」を不正なリンクを踏ませるなどの行為を通じて作り出すことができる。
このようなリクエストはwebアプリケーションのホストに対するリクエストであるため、ブラウザからそのホスト用のcookieの状態が伝えられ、それを受け取ったアプリケーションは本人からの正常なアクセスだと判断してしまう。

CSRFはこの性質を悪用し、ログイン状態でなければできない操作を、外部サイトから実行させようとする。

CSRFを防ぐには、そのリクエストがユーザーの意図によるものかを確認する必要がある。
一般的には**同じwebアプリケーションから生じたリクエストであることを証明するためのセキュリティトークンを発行し、照合する**方法がよく用いられる。

Railsはこの発行と照合の仕組みを標準で用意している。トークンの発行は、フォームから送られる情報にセキュリティトークンを含めるという形で行われる。これはRailsの提供しているform_with等のヘルパーを使ってフォームを生成すれば自動で行われる。トークンが正しく送られてきているかの照合はコントローラで行うが、この仕組は標準で組み込まれているので、どこかに照合を行うための設定などを記述する必要はない。

CSRFを防ぐ仕組みはGETリクエストには適用されない。したがって、データを変更するような処理をGETリクエストで行うようにしてしまうと、対策の意味をなさなくなる。
GETリクエストは単純な情報の読み出しのために使い、状態変化や何ら化の作業を伴う操作はPOSTリクエストで行うように徹底すること。


### Ajaxリクエストへのセキュリティトークンの埋め込み

8章でAjaxに関する説明があるので、それまで一旦pend


## インジェクションに注意する
インジェクションはwebアプリケーションに悪意のあるスクリプトやパラメータを入力し、それが評価されるときの権限で実行させる攻撃。

インジェクション攻撃の標的となるのは、ユーザーがデータ入力可能なところ全て。フォームであたり、リクエストパラメータであったりと、あらゆるデータの入り口が対象になる。

代表的なインジェクションとして以下を解説する

- XSS
- SQLインジェクション
- Rubyコードインジェクション
- コマンドラインインジェクション

### XSS(クロスサイトスクリプティング)
ユーザーに表示するコンテンツに悪意のあるスクリプト(主にJS)を仕掛け、そのコンテンツを表示したユーザーにスクリプトを実行させることで任意の操作を行う攻撃

JSはブラウザ上で動作し、ユーザーの情報を読み取ったり任意のアクションを実行させたりすることができる。
さらにはcookieの読み書きも行えるなどのお大きな権限も持っている。

XSSを防止するには、ユーザーの入力した文字列を出力する際に、そのままHTML内に埋め込んで表示するのではなく、危険なHTMLタグとして解釈されないよう加工してから表示をするようにする。
Railsのビューでは、ユーザーの入力した文字列を出力する際に自動的にHTMLをエスケープしてくれる。
例えば「&」「"」「<」「>」は、無害なHTML表現形式「&amp;」「&quot;」「&lt;」「&gt;」に置き換えられる。

具体例を見てみる。
仮に、@commentというインスタンス変数に"<script>alert('Hello');</script>という文字列が入っており、次のようなビューがあるとする。

ビューファイル
```
div
  = @comment
```

すると、次のようなHTMLを生成してくれる。これならば、ブラウザが「alert('Hello');」をscriptとして実行してしまうことはない。

HTML
```
<div>&lt;script&gt;alert(&#39;Hello&#39;);&lt;/script&gt;</div>
```

この仕組は便利だが、どんなときにもビューに動的に埋め込む文字列を必ずエスケープしたいかというと、そうとも限らない。
このようなときは、「raw」ヘルパーや「String#html_safe」を使うとエスケープをスキップできる。

ビューファイル

```
= raw @comment
```

```
= @comment.html_safe
```

```
== input_value
```

このようにエスケープをスキップする場合は、XSSが発生しないように自分で注意する必要がある。


### SQLインジェクション
「where」メソッドなど、ActiveRecodeのいくつかのクエリメソッドはSQL文字列を直接渡して条件指定することができる。
このとき、SQL文字列にユーザーが入力した値を直接埋め込まないように注意すること。

SQLインジェクションとは、データ入力時に悪意のあるSQLを入力することで攻撃を試みる。
例えば、ユーザー名の入力欄に「'OR'1'))--」という文字列を入力したとする。この入力値をparams[:user_name]として受け取って次のようにデータベースを検索するコードがあったとする

```
emails = User.where("name = '{params[:user_name]}'").map(&:email)
```

本来は、このコードは指定されたユーザー名を持つユーザーのメールアドレスを取り出す意図だが、入力値をそのまま埋め込んでしまっているため、次のようなSQL文字列が作成され、実行されてしまう

```
SELECT "users".* FROM "users" WHERE (name = ''OR'1'))--')
```

この例では、悪意あるユーザーが紛れ込ませたSQL「'OR'1'))--」が巧妙に埋め込まれることにより、いつも真となる「OR '1'」という検索条件が追加されている。「--」以降はSQLでは全てコメントとみなされるので、他の条件が続いた場合もそれらを無視することができる。そのため、悪意あるユーザーの狙い通りに全ユーザーのメールアドレスを取り出されてしまう。

SQLインジェクションを防ぐためには、ユーザーの入力した文字列をそのままSQLに埋め込むのではなく、エスケープ等の加工を行ってから埋め込む必要がある。

Railsでは、クエリメソッドに対してハッシュで条件を指定すると、自動的に安全化のための処理を行ってくれる。そのため、基本的にはハッシュで条件を指定するようにするのがおすすめ。

例 コントローラファイル
```
users = User.where(name: params[:name])
```

すると、以下のようなSQLが生成、実行される

```
SELECT "users".* FROM "users" WHERE "users"."name = $1 [["name", "'OR'1'))--"]]
```

ただし、ハッシュでは作れないSQLを作るために、クエリメソッドにSQLを直接書きたい場合もある。このときは、SQLに文字列を直接埋め込まずにプレースホルダを利用するようにする。
すると、SQLを操作しようとする「'」のような入力をエスケープしてくれる。

コントローラファイル
```
users = User.where('name = ?', params[:name])
```

上記のコードは以下のようなSQLを生成、実行する。

```
SELECT "users".* FROM "users" WHERE (name = ''' OR ''1'')==')
```

### rubyコードインジェクション
Rubyにはあるオブジェクトのメソッドを任意に呼び寄せる「Object#send」メソッドが存在する。このメソッドは動的に動作を変えたりするのに便利な半面、使い方を謝ると重大なセキュリティ問題を起こす可能性がある。

特に、**ユーザーからの入力をそのまま**sendに渡すことは避ける。

コントローラファイル

```
users = User.send(params[:scope])
```

この例ではUserモデルに適用するscopeを任意に切り替えられるようにしている。これでは、意図せぬ範囲のデータまで見せてしまうのはもちろん、プライベートメソッドにまで呼び寄せてしまう危険がある。もしユーザーが「exit」という文字列をparams[:scope]に入力してきたとしたら、上記のコードを実行した途端に、アプリケーションが終了してしまう。

避けるための１つの方法としては、ユーザーの入力をcase式などで切り分けて、個々のメソッドを呼び出す部分を固定的にコーディングすること。
別の方法としては、sendに渡して良いメソッド名をホワイトリスト方式で限定すると良い。


### コマンドラインインジェクション
RailsアプリケーションからOSのコマンドを実行したいことがあるかもしれない。
たまにしか発生しないゆえに意識しづらい脆弱性がコマンドラインインジェクション。

例えば、gitリポジトリと連携したいwebアプリケーションがあるとする、
このアプリケーションには、gitリポジトリ内の、ユーザーの指定したブランチのログを表示する機能があるとする。このために、アプリケーション内部では「git log」というコマンドを実行するが、コマンドのオプションにユーザーの入力したブランチ名を渡す必要がある。

このようなことを実現したい場合、実装方法によってはコマンドラインインジェクションの原因となってしまう。

Rubyで一番手軽にコマンドを呼び出して標準出力を得る方法は、バッククオート記法を使う方法。
しかし、次のように書いてしまうの危険。

コントローラファイル
```
`git log -10 #[params[:branch_name]]`
```

params[:branch_name]に「master」等の実在するブランチ名が想定通りに渡されるなら問題はない。しかし、もし悪意あるユーザーが「; rm *」という文字列を入れてきた場合

```
> git log -10 ; rm *
```

このようにして、どんなコマンドでも実行できてしまう。

このような場合はドノようにして防ぐとよいか。

Rubyでコマンドを呼び出す方法には、他に「Karnel.#system」「Kernel.#spawn」メソッド、「Open3」モジュール等があるこれらのめそっどでは引数を「コマンド名、パラメータ」の形式で渡すことができる。この方法であればシェルを介さないため安全。

例
```
require 'open3'
srdout, stderr, status = Open3.capture3("git", "log", "-10", params[:branch_name])
```

### Content Security Policy (CSP)を設定する
Content Security Policy (CSP)は、XSSやパケット頭盗聴といった特定の攻撃をブラウザ側で軽減するための仕組み。webページのコンテンツの取得元や取得方法のポリシーを、webサーバからブラウザに伝えることができる。

CSPを設定するには、webサーバからHTTPヘッダに「Content-Security-Policy」を組み込む。他にも「<meta>」タグを用いる方法がある。

RailsではHTTPヘッダにCSPを組み込むための機能が用意されていて、そのための設定は「content_security_policy.rb」に記述する。
標準ではコメントアウトされているため、コメントアウトを外し、プロダクトの性質に合わせて設定を調整する。

# 6-8 アセットパイプライン
javascript、CSS、画像などのリソース（アセット）を効率的に扱うための仕組みである「アセットパイプライン」日ついて解説する
アセットパイプラインはsprockets-rails gemにて提供されるSprockets機能ので、デフォルトに有効になっている

アセットパイプラインでは、開発者が書いたjsやcssを、最終的にアプリを使う上で都合の良い状態するためのパイプライン処理を行う

<大まかな処理>
1. 高級言語のコンパイル
    CoffeeScript、SCSS、ERB、Slim等で記述されたコードをコンパイルして、ブラウザが認識できるjsファイルとして扱う
2. アセットの連結
    複数のjs、cssファイルを1つのファイルに連結することで読み込みに必要となるリクエスト数を減らし、全ての読み込みが終わるまでの時間を短縮する
3. アセットの最小化
    スペース、改行、コメントを削除してファイルを最小化し、通信量を節約する
4. ダイジェストの付与
    コードの内容からハッシュ値を算出してファイル名の末尾に付与する。
    このようにすると、コードが変更されればファイル名が変更されるため、ブラウザのキャッシュの影響で修正が反映されないという問題を防ぐことができる

## 環境による挙動の違い
アセットパイプラインはdevelop環境とproduction環境で、それぞれの目的に対して便利に鳴るように挙動が異なる

### development環境
- 高級言語のコンパイル、ダイジェスト付与は逐一自動で行われる。開発者が自分でコンパイルする必要がなくスムーズに開発を行える
- アセットの連結と最小化はおこなれ無い(デバッグのしやすさを考慮して)
- アセットの連結を行っていないため、ページのソースを確認するとファイルす分のlink,scriptタグが生成される
(ファイルの例はp268を参照)

### production環境
- アセットパイプラインの機能をフルに活用して、1つのjsファイル、1つのCSSファイルを生成しておき、それを配信するという形が基本。
development環境とは異なり、高速化のためにアセットの連結・最小化が行われる。連結が行われているため、ペーぞのソースを確認すると次のようにjsファイルとcssファイルが１つずつ読み込まれている。


## ブラウザにアセットを読み込ませる
CSSやjs等のアセットは、通常web画面にアクセスしたブラウザが、サーバーから返されたHTML内にあるscriptタグ、linkタグ等のリンク情報を読み取ることによって読み込まれ、利用できるようになる。
このようなリング情報をRailsではどのように実装するのか見ておく

Railsではcssを読み込むにはstylesheet_link_tag,jsを読み込むにはjavascript_include_tagというヘルパーメソッドを使う。
今回はapplication.html.slimで読み込みを行っている。

```
= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload'
= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload'
```

ここで読み込まれているapplication.cssとapplication.jsはアセットパイプラインによって連結された結果のファイル。

## 連結結果のファイルをどうやって生成するか
プログラマがapp/assets/application.cssやapp/assets/application.jsと言った「マニフェストファイルに記述する」
マニフェストファイルには、管理しやすいように分類して別々のファイルとして作成した個別のCSSファイルやjsファイルをこのように連結したい、という指定を記述することになる。
最終的に出力したapplication.cssなどのファイル毎に作成する

## マニフェストファイルを記述する
マニフェストファイルは新規にRailsのアプリケーションを作成した時点で、js,cssのそれぞれについて以下のマニフェストファイルが作成される

- app/assets/application.css
- app/assets/application.js

マニフェストファイルに、特定の記法(ディレクティブ)で、結合する(取り込む)ソースコードを指定する。

次に具体的な書き方を見ていく
まずはjsのマニフェストファイルから

**rails6からassets pipelineがデフォルト無効になり、jsはwebpackerで管理されるようになっている。なので今のコードと本に記載してある部分で違いがある点に注意**

```
require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
```

- require: 指定したjsファイルの内容を、記述した位置に取り込む。このアプリではrails-ujsやturbolinksといったjsを指定している
- require_tree: 指定されたディレクトリ配下の全ファイルの内容を結合し、記述した位置に取り込む

ここで記述されたjsファイルはマニフェストファイルの位置からはどこにも見当たらない。これらはアセットの「探索パス」の設定をもとにsprocketsが引き当てる。

CSSも考え方は同じ。ただし、ディレクティブを記述する方法が異なる、
このアプリではSassで書くように置き換えているので、Sassの@importを利用して記述していく。

なお、sassでマニフェストファイルを記述する場合は、sprocketsの方法と併用しないこと。

## アセットの探索パス
マニフェストで指定するjsやcssのファイルは、アセットの探索パスの設定をもとに引き当てられる。
デフォルトではapp/assets, lib.assets, vendor/assets が探索パスに設定されている。

新しく探索パスを設定したい場合はRails.application.cofig.assets.pathsに探索パスを追加する
通常はconfig/initialize/assets.rbの中で記述する

どんなパスが探索対象になっているのかはコンソールから確認することができる

```
$ bin/rails c
irb(main):002:0> puts Rails.application.config.assets.paths
/Users/senohirona/src/github.com/rails-on-site/taskleaf/app/assets/config
/Users/senohirona/src/github.com/rails-on-site/taskleaf/app/assets/images
/Users/senohirona/src/github.com/rails-on-site/taskleaf/app/assets/stylesheets
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/actioncable-6.0.3.4/app/assets/javascripts
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/activestorage-6.0.3.4/app/assets/javascripts
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/actionview-6.0.3.4/lib/assets/compiled
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/turbolinks-source-5.2.0/lib/assets/javascripts
/Users/senohirona/src/github.com/rails-on-site/taskleaf/node_modules
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/popper_js-1.16.0/assets/javascripts
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/bootstrap-4.5.3/assets/stylesheets
/Users/senohirona/.rbenv/versions/2.6.5/lib/ruby/gems/2.6.0/gems/bootstrap-4.5.3/assets/javascripts
```

# 6-9 production環境でアプリケーションを立ち上げる
本番環境でアプリケーションを動かすための基本的な事柄を解説していく
本来は、アプリケーションを本番稼働させる場合は、動作させるのはサーバー上であり、デプロイ操作はCapistoranoなどで自動化することが多い。
ここでは、ローカルPC上でRailsのproduction環境の扱い方を解説していく

## アセットのプリコンパイル
production環境では、リクエストを高速に処理できるように、予めアセットパイプラインを実行して静的ファイルを生成しておき、生成済みのファイルをリクエストのたびに配信する。
プリコンパイル: 「予めアセットパイプラインを実行して静的ファイルを作成する」処理のこと

prroduction環境ではこのプリコンパイルを必ず実行する必要がある。

プリコンパイルはrailsのコマンドで用意されている。

プリコンパイルを実行したことにより、public/assetsディレクトリ配下にコンパイルされたjs,cssファイルが生成される


```
$ bin/rails assets:precompile
yarn install v1.22.0
[1/4] 🔍  Resolving packages...
success Already up-to-date.
✨  Done in 0.50s.
yarn install v1.22.0
[1/4] 🔍  Resolving packages...
success Already up-to-date.
✨  Done in 0.42s.
I, [2020-12-24T13:49:42.523441 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/manifest-b4bf6e57a53c2bdb55b8998cc94cd00883793c1c37c5e5aea3ef6749b4f6d92b.js
I, [2020-12-24T13:49:42.523718 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/manifest-b4bf6e57a53c2bdb55b8998cc94cd00883793c1c37c5e5aea3ef6749b4f6d92b.js.gz
I, [2020-12-24T13:49:42.524112 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/application-e8d55915950a5e38080539476708e827f1f19dc4f6b7a7beae014c0deaa00888.css
I, [2020-12-24T13:49:42.524500 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/application-e8d55915950a5e38080539476708e827f1f19dc4f6b7a7beae014c0deaa00888.css.gz
I, [2020-12-24T13:49:42.525070 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/sessions-04024382391bb910584145d8113cf35ef376b55d125bb4516cebeb14ce788597.css
I, [2020-12-24T13:49:42.541999 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/sessions-04024382391bb910584145d8113cf35ef376b55d125bb4516cebeb14ce788597.css.gz
I, [2020-12-24T13:49:42.542840 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/tasks-04024382391bb910584145d8113cf35ef376b55d125bb4516cebeb14ce788597.css
I, [2020-12-24T13:49:42.543191 #50651]  INFO -- : Writing /Users/senohirona/src/github.com/rails-on-site/taskleaf/public/assets/tasks-04024382391bb910584145d8113cf35ef376b55d125bb4516cebeb14ce788597.css.gz
Everything's up-to-date. Nothing to do
```

## 静的ファイルの配信サーバーを設定する
Railsには、静的なファイルを配信する機能があり、publicディレクトリ下のファイルを配信してくれる。

本番環境ではｍ静的ファイルの配信はWebサーバーに担わせることが一般的なので、Railsには静的ファイル配信機能をon/offする設定が存在する。
production環境は基本的にoffに設定されている。

今回はonに設定を変更する
on/offの設定はproduction.rbに記載されている
変数`RAILS_SERVE_STATIC_FILES` が存在しない限りfalseになるように設定されている。

```
  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
```

これをtrueに変えたいので~/.zshrcに環境変数を追加する
(一時的なものなので、本を一通り終わらせた後は削除する)

```
export RAILS_SERVE_STATIC_FILES=1
```

## production環境用のデータベースを作成する
データベースを作成するには、development環境やtest環境と同じくbin/rails db:migrateコマンドを用いる
bin/rails db:migrateコマンドはデータベース設定ファイル(database.yml)の設定内容に従って動作するので、先にこちらを確認する。

```
production:
  <<: *default
  database: taskleaf_production
  username: taskleaf
  password: <%= ENV['TASKLEAF_DATABASE_PASSWORD'] %>
```

設定自体は問題ないが、このままデータベースを作成しようとしても上手く行かない。
次の2つの準備が必要

- postgresqlにtaskleafというユーザー(ROLE)を追加する
- taskleafユーザーがデータベースに接続する際に使うパスワードを、環境変数「TASKLEAF_DATABASE_PASSWORD」で取得できるようにする

### postgresqlにtaskleafというユーザー(ROLE)を追加する

```
$ createuser -d -P taskleaf
Enter password for new role: [パスワードを入力。ここでは'passwordとする']
Enter it again: [再度パスワードを入力]
```
### taskleafユーザーがデータベースに接続する際に使うパスワードを、環境変数「TASKLEAF_DATABASE_PASSWORD」で取得できるようにする

設定したパスワードを環境変数「TASKLEAF_DATABASE_PASSWORD」にセットしてconfig/database.ymlから取得できるようにする。

~/.zshrc
```
export TASKLEAF_DATABASE_PASSWORD=password
```

これで準備が整ったのでdb:createとdb:migrateを実行する

```
$ RAILS_ENV=production bin/rails db:create db:migrate
Created database 'taskleaf_production'
== 20201118102721 CreateTasks: migrating ======================================
-- create_table(:tasks)
   -> 0.0044s
== 20201118102721 CreateTasks: migrated (0.0045s) =============================

== 20201123011521 ChangeTasksNameNotNull: migrating ===========================
-- change_column_null(:tasks, :name, false)
   -> 0.0010s
== 20201123011521 ChangeTasksNameNotNull: migrated (0.0010s) ==================

== 20201124010758 CreateUsers: migrating ======================================
-- create_table(:users)
   -> 0.0064s
== 20201124010758 CreateUsers: migrated (0.0064s) =============================

== 20201124085400 AddAdminToUsers: migrating ==================================
-- add_column(:users, :admin, :boolean, {:default=>false, :null=>false})
   -> 0.0012s
== 20201124085400 AddAdminToUsers: migrated (0.0012s) =========================

== 20201125103453 AddUserIdToTasks: migrating =================================
-- execute("DELETE FROM tasks;")
   -> 0.0007s
-- add_reference(:tasks, :user, {:null=>false, :index=>true})
   -> 0.0029s
== 20201125103453 AddUserIdToTasks: migrated (0.0038s) ========================
```

## config/master.keyが存在する事を確認する
productionモードでアプリケーションを利用する場合、Railsがproduction環境用の秘密情報を複合するために利用する鍵の情報が必要になる。
この鍵はconfig/master.keyファイルもしくは環境変数「RAILS_MASTER_KEY」。

rails newをしている場合には自動的にconfig/master.keyが生成される
(あるのを確認)

## productionモードでサーバを起動する
ここまでで設定は終了
オプション「--environment=production」を追加してサーバをproductionモードに起動してみる。

```
$ bin/rails s --environment=production

=> Booting Puma
=> Rails 6.0.3.4 application starting in production
=> Run `rails server --help` for more startup options
Puma starting in single mode...
* Version 4.3.6 (ruby 2.6.5-p114), codename: Mysterious Traveller
* Min threads: 5, max threads: 5
* Environment: production
* Listening on tcp://0.0.0.0:3000
Use Ctrl-C to stop
^C- Gracefully stopping, waiting for requests to finish
```

ログイン画面が表示されればOK

## production環境用の秘密情報の管理
credentials: 特定の方式で管理されるproduction環境用の秘密情報。
秘密情報を構造化して記述してリポジトリで管理できるようにするが、このときリポジトリに入る内容はある1つのキーで暗号化される。そして、そのキーはリポジトリの外で管理しておき、アプリケーションに伝えて、アプリケーションが複合して利用できるようにする。
これによって、多くの秘密情報を一括で簡単に管理できるにも関わらず、秘密情報の漏洩を防ぐ事ができるようになる

## 秘密情報の暗号化・複合
production環境用の秘密情報(credentials)はconfig/credentials.yml.encに記述する。このファイルは暗号化された状態で保存される。
開発者がこのファイルの内容を編集するには、Railsの用意している専用のコマンドを通じて行う。
Railsアプリケーションがproduction環境で起動された際には、master.keyファイルもしくはRAILS_MASTER_KEY環境変数からキー情報を取り出して秘密情報を内部的に複合して利用する

### credential.yml.encの初期状態を見てみる
catコマンドで中身を確認できる

```
$ cat config/credentials.yml.enc
M4gK/NmWQqC1S6biV5qjg24LIAVnz5DKG6UP7S8t5qLS6J3IRBfSAFNSGsEhQNwWsPJwy6RmeviNpNUdcokSW6kRZRIKqddAB2OosFUQ0nlrwYo3Wi1HbY3jsLMJqn4T2BwNmTL5eDzW3ZWs05M1JzthJhuOkbmb+kRQvCmIM7P1g99p0moNYi6CvxXDNIcVgQll28/V1JvZJeT0JmVdeBeZVAkGZ91cjDIc/o8P/S+VZrRp3ArapExIghgZcYGVb7GwjsZVeg7Xv3AScp4Z4Lb+/FZxH0dUdOEfOqlyTj58jykgiDg83ZALpgh2iXrcli7Tf0JoUpT9qK5TeWISgQeBOrSfcjVbXDLfhWNu8FbEkteiw1InAe8U7zJ82ItUC0FR7m6/NpYra+xeqERp5KdweU1EZEl294BC--vPBAkumohkH2aERY--3tGW+0CYipP6JddJNmuy7Q==%
```

暗号化されている
複合された内容を確認するには以下コマンドを利用する

```
$ bin/rails credentials:show
# aws:
#   access_key_id: 123
#   secret_access_key: 345

# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: 681aa2d5223dd9fb7808790dcbc543f3e4996a0cdec43b2c96ce7b5f529ce144b44d81728af5a2770a37584d30725e49bc9d696153f1bb092fa177420d497568
```

### credentialsの編集
編集するには以下コマンド利用する

```
$ bin/rails credentials:edit
```

## アプリケーションからcredentialsを参照する
railsコンソールから以下のようなコマンドで確認が可能

```
$ bin/rails c
Running via Spring preloader in process 53025
Loading development environment (Rails 6.0.3.4)
irb(main):001:0> Rails.application.credentials.secret_key_base
=> "681aa2d5223dd9fb7808790dcbc543f3e4996a0cdec43b2c96ce7b5f529ce144b44d81728af5a2770a37584d30725e49bc9d696153f1bb092fa177420d497568"
```
