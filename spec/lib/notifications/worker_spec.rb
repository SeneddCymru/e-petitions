require 'rails_helper'

RSpec.describe Notifications::Worker do
  let(:message) { double(:message) }
  let(:event) { double(:event) }
  let(:notifications) { Notifications::Notification }

  describe "#perform" do
    context "when the notification is successfully processed" do
      it "deletes the message" do
        expect(message).to receive(:delete)
        expect(notifications).to receive(:process!).and_return(true)

        subject.perform(message, event)
      end
    end

    context "when the notification is not successfully processed" do
      it "doesn't delete the message" do
        expect(message).not_to receive(:delete)
        expect(notifications).to receive(:process!).and_return(false)

        subject.perform(message, event)
      end
    end
  end
end
