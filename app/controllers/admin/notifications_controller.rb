class Admin::NotificationsController < Admin::AdminController
  before_action :find_notifications, only: [:index]
  before_action :find_notification, only: [:show, :update, :destroy]

  before_action only: :index do
    request.format = :js if request.xhr?
  end

  def index
    respond_to do |format|
      format.js
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  private

  def find_notifications
    @notifications = Notifications::Notification.search(search_params)
  end

  def find_notification
    @notification = Notifications::Notification.find(notification_id)
  end

  def search_params
    params.permit(:q, :page, :count)
  end

  def notification_id
    params.require(:id)
  end
end
