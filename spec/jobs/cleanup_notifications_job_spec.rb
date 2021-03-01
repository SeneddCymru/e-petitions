require 'rails_helper'

RSpec.describe CleanupNotificationsJob, type: :job do
  let!(:notification_1) { FactoryBot.create(:notification, created_at: "2020-09-01T23.59.59+01:00") }
  let!(:notification_2) { FactoryBot.create(:notification, created_at: "2020-09-02T00.00.01+01:00") }

  let(:time) { "2020-09-02T00:00:00+01:00" }
  let(:scope) { Notifications::Notification.all }

  around do |example|
    travel_to("2021-03-02 00:00") { example.run }
  end

  it "removes notifications older than 180 days" do
    expect {
      described_class.perform_now(time)
    }.to change {
      scope.include?(notification_1)
    }.from(true).to(false)
  end

  it "doesn't remove notifications younger than 180 days" do
    expect {
      described_class.perform_now(time)
    }.not_to change {
      scope.include?(notification_2)
    }.from(true)
  end
end
