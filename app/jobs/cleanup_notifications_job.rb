class CleanupNotificationsJob < ApplicationJob
  queue_as :low_priority

  def perform(time)
    Notifications::Notification.cleanup!(time.in_time_zone)
  end
end
