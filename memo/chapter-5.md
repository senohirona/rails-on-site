# 5-1 テストについて
自動テスト: コードが変更されるたびに自動テストを動かして、エラーの有無を確認すること。
これにより、コードに意図しない不具合や挙動変更が混入することを防ぐことができる。

この章ではまず、テストを書くことのメリットについて補足した上でRspecとCapybaraをりようしてシステムテストを追加していく

# 5-2 テストを書くことのメリット

## テスト全体にかかることストの削減
アプリケーションを利用し始めたあとで機能の追加を行った場合は、新機能だけではなく様々な既存機能が想定通りに動いているかをカクニンする必要がある。
自動テストを備えていれば、動作確認の大部分を自動テストに任せることができ、テスト全体にかかるコストを大幅に削減できる。

## 変更をフットワーク軽く行えるようになる


# 5-3 テスト用ライブラリ

## RSpec
RSpec:RubyにおけるBDD(振舞駆動開発)のためのテスティングフレームワーク
要求仕様をドキュメントに記述するような感覚でテストケースを記述することができる。

## Capybara
Capybara:webアプリケーションのE2Eテスト用のフレームワーク。RSpecなどのテスティングライブラリと組み合わせて使う。
webアプリケーションのブラウザ操作をシミュレーションできる他、実際のブラウザと組み合わせてJavaScriptの動作まで含めたテストを行うことができる。

## FactoryBot
テスト用データの作成をサポートするgem。
テスト用データをかんたんに用意し、テストから呼び出して利用することができる。


# 5-4 テストの種類

## モデルのテスト
モデルのテストでは検証やデータの制御、複雑なロジックの挙動などを個別のテストケースとして記述する。
システムテストをなどでは行いづらい、様々な条件下での僅かな挙動の違いをカクニンするのに向いている。

## 結合テスト
モデルのテストとシステムテストの間を埋めるテスト。
APIのテストに利用されることが多い

## ルーティング、メーラー、ジョブのテスト
複雑なルーティングや他のテストで置き換えづらいメーラーやジョブのテストでは用意する場合がある

# 5-5 System specを書くための準備

Sytem spevを書くために、Rspec,capybara, factory bot をインストールする

## RSpecのインストールと初期準備

rspec-railsというgemを追加することで、RSpecとRSpecのrails用の機能がインストールされる

インストールが終わったら、以下のgenerateコマンドを実行する。
これによりRSpecに必要なディレクトリや設定ファイルが作成される。

```
bin/rails g rspec:install
```

spec/spec_helper.rbはRSpecの全体的な設定を書くためのファイル。
spec/rails_helper.rbはrails特有の設定を書くためのファイル

最後にRailsアプリケーションを作成した時に自動で作られたtestディレクトリを削除しておく。
これはRSpecではspecというディレクトリにspecを格納していく仕組みのため。

## Capybaraの酒器準備
capybara本体は rails new時のbundle installによってすでにインストールされている。
なので、ここではRspecでcapybaraを利用するための準備を行う。
spec/spec_helper.rbに次のように編集する。

```
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'capybara/espec'
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
```

## FactoryBotのインストール
factory_bot_railsをgemfileに追記する


## Rspecの基本形

書き方

```
describe [仕様を記述する対象(テスト対象)], type: [Specの種類] do
  context [ある状況・状態] do
    before do
      [事前準備]
    end

    if [仕様の内容(期待の概要)] do
      [期待する挙動]
    end
  end
end
```

ここで出てくる用語は以下2タイプに分けることができる

- テストケースを整理・分類する...describe, context
- テストコードを十個する...before, it


describe: 何について仕様を記述しようとしているのかを記述する
context: テストの内容を「状況・状態」のバリエーションごとに分類するために利用する。
before: その領域全体の「前提条件」を実現するためのコードを記述する。
it: 期待する動作を文章と、ブロック内のコードで記述する。


# 5-7 Factory Botでテストデータを作成できるように準備する
system specで利用するためのファクトリを定義していく

このアプリではTaskとUserの2つのモデルを作成した。
例えば、ログイン動作を確認するには事前にデータベースにUserデータが登録されている必要がある。
同様に、タスク一覧で登録済みのタスクが適切に表示されていることを確認するには、事前にデータベースにTaskデータが登録されている必要がある。
そこで、TaskとUserについて、それぞれ基本的なファクトリを用意しておく。

1. FactoryBotでデータを作成するための「テンプレート」を用意しておく
2. SystemSpecの適切な　beforeなどでFactoryBotのテンプレートを利用してテスト用データベースにテストデータを投入する

Userのファクトリ

```
FactoryBot.define do
  factory :user do
    name{'テストユーザー'}
    email{'test1@example.com'}
    password{'password'}
  end
end
```



Taskのファクトリ

```
    factory :task do
      name{'テストを書く'}
      description{'RSpec&Capybara&FactoryBotを準備する'}
      user
    end
  end
```

userのみ記述の意味:
「先程定義した :userという名前のFactoryを、Taskモデルに定義されたuserという名前の関連を生成するのに利用する」という意味になる。


# 5-8 タスクの一覧表示機能のSystem Spec
実際にSpecのコードを書いていく。
Specの内容としては以下

1. 最初のbefore
- ユーザーAを作成しておく(テストデータの準備)
- 作成者がユーザーAであるタスクを作成しておく(テストデータの準備)
2. 2つ目のbefore
- ユーザーAでブラウザからログインする(前提となっているユーザーの操作をしておく)
3. it
- ユーザーAの作成したタスクの毎生姜画面上に表示されていることを確認

## ユーザーAを作成しておく
ログインしたりタスクを用意するために必要となるユーザーデータをデータベースに登録する。
それにはFactoryBot.createというメソッドで用意した:userファクトリを指定して、Userオブジェクトの作成登録を行う

## 作成者がユーザーAであるタスクを作成しておく
次に一覧画面を表示したときに表示されてほしいタスクデータを用意する
ここでは:taskファクトリを使ってデータを作る。

## ユーザーAでログインする
ブラウザ上でユーザーAがログインする操作をSpec上で記述していく

操作の細かいステップ
1. ログイン画面にアクセスする
2. メールアドレスを入力する
3. パスワードを入力する
4. 「ログインする」ボタンを押す

### ログイン画面にアクセスする
特定のURLでアクセスする操作はvisit[URL]という書き方で実現できる。

### メールアドレスを入力する
画面上では「メールアドレス」というラベルが付いたテキストフィールドにメールアドレスを入れる操作になる。
テキストフィールドに値を入れるにはfill_inメソッドを利用する。

### パスワードを入力する
メールアドレスと同様に入力

### 「ログインする」ボタンを押す
ボタンを押すにはclick_buttonメソッドを使う

### 作成済みのタスクの名称が画面上に表示されていることを確認
ユーザーAが作成者になっているタスクがちゃんと表示されていることを確認する。

# 5-9 他のユーザーが作成したタスクが表示されないことの確認
ユーザーBに対してユーザーAの作成したタスクが見えないことを確認する

確認手順
1. ユーザーAと、ユーザーAのタスクを作成する
2. ユーザーBを作成する
3. ユーザーBでログインする
4. ユーザーAのタスクが表示されていないことを確認する

手順の1~3まではユーザーAのときの作業と同じ
4. ユーザーAが作成したタスクが表示されないことを確認するitの部分を記述していく。
タスクが表示されている事を期待したいときは「expect(page).to have_content '最初のタスク'」というコードを書いた
今回は表示されていないことを期待するので「have_no_content」というマッチャを利用して記述する