require 'rails_helper'

RSpec.describe "notify:cleanup", type: :task do
  around do |example|
    travel_to("2021-03-01 07:10") { example.run }
  end

  it "enqueues a cleanup task" do
    expect {
      subject.invoke
    }.to have_enqueued_job(
      CleanupNotificationsJob
    ).with("2020-09-02T00:00:00+01:00").on_queue(:low_priority)
  end
end
