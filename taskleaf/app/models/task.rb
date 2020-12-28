class Task < ApplicationRecord
    has_one_attached :image
    validates :name, presence: true
    validates :name, length: {maximum: 30}
    validate :validate_name_not_including_comma

    belongs_to :user

    scope :recent, -> { order(created_at: :desc)}

    def self.ransackable_attributes(auth_object = nil)
      %w[name created_at]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end

    def self.csv_attributes
      # CSVにどの属性をどの順番で出力するかをcsv_attributeというクラスメソッドから得られるように定義する
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

    # fileという名前の引数でアップロードされたファイルの内容にアクセスするためのオブジェクトを受け取る
    def self.import(file)
      # CSV.foreachを使って、CSVファイルを1行ずつ読み込む
      CSV.foreach(file.path, headers: true) do |row|
        # CSV1行ごとに、Taskインスタンスを生成する(newはTask.newと同意)
        task = new
        # 生成したTaskインスタンスの各属性に、CSVの1行の属性を加工して入れ込む
        task.attributes = row.to_hash.slice(*csv_attributes)
        # Taskインスタンスをデータベースに登録する
        task.save!
      end
    end

    private

    def validate_name_not_including_comma
      errors.add(:name, 'にカンマを含めることはできません') if name&.include?(',')
    end
end
