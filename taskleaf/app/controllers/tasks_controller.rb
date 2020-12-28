class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  def index
    @q = current_user.tasks.ransack(params[:q])
    @tasks = @q.result(distinct: true).page(params[:page])

    respond_to do |format|
      # HTMLフォーマットについては特に処理を指定しない(index.html.slimを表示する)
      format.html
      # send_dataメソッドを使ってレスポンスを送り出し、送り出したデータを部サウザからファイルとしてダウンロードできるようにする
      format.csv{send_data @tasks.generate_csv, filename: "tasks-#{Time.zone.now.strftime('%Y%m%dS')}.csv"}
    end
  end

  def show
    @task = current_user.tasks.find(params[:id])
  end

  def new
    @task = Task.new
  end

  def edit
    @task = current_user.tasks.find(params[:id])
  end

  def update
    task = current_user.tasks.find(params[:id])
    task.update!(task_params)
    redirect_to tasks_url, notice: "タスク「#{task.name}」を更新しました。"
  end

  def create
    @task = current_user.tasks.new(task_params)

    # 「戻る」ボタンが押された場合は、現在のタスクの内容を引き継いだ状態で新規登録のフォーム画面を表示する
    if params[:back].present?
      # 新規登録フォームの画面を表示する処理はここで定義している
      render :new
      return
    end

    if @task.save
      SampleJob.perform_later
      logger.debug "task: #{@task.attributes.inspect}"
      redirect_to @task, notice: "タスク「#{@task.name}」を登録しました。"
    else
      render :new
    end
  end

  def destroy
    task = current_user.tasks.find(params[:id])
    task.destroy
    redirect_to tasks_url, notice: "タスク「#{task.name}」を削除しました。"
  end

  def confirm_new
    # 新規登録画面から受け取ったパラメータをもとにタスクイブジェクトを作成して、@taskに代入
    @task = current_user.tasks.new(task_params)
    # 問題があれば検証エラーメッセージとともに出力する
    render :new unless @task.valid?
  end

  def import
    # 画面上のフィールドからアップロードされたファイルオブジェクトを引数に、関連越しに先程実装したimportメソッドを呼び出している
    current_user.tasks.import(params[:file])
    #インポートが終わった後にタスク一覧画面に遷移する
    redirect_to tasks_url, notice: "タスクを追加した"
  end

  private

  def task_params
    params.require(:task).permit(:name, :description, :image)
  end

  def set_task
    @task = current_user.tasks.find(params[:id])
  end
end
