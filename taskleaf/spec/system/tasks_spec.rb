require 'rails_helper'

describe 'タスク管理機能', type: :ststem do
  describe '一覧表示機能' do
    before do
     user_a = FactoryBot.create(:user, name: 'ユーザーA', email: 'example.com')
      # ユーザーAを作成しておく
      # 作成者がユーザーAであるタスクを作成しておく
    end
    content 'ユーザーAがログインしている時' do
      before do
        # ユーザーAでろぐいんする
      end
      it 'ユーザーAが作成したタスクが表示される' do
        # 作成済みのタスクの名前が画面上に表示されていることを確認
      end
    end
  end
end
