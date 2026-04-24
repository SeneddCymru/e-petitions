require 'rails_helper'

RSpec.describe ExtendPetitionDeadlinesJob, type: :job do
  let!(:petition) { FactoryBot.create(:open_petition) }

  context "when signature collection is not disabled" do
    before do
      expect(Site).to receive(:signature_collection_disabled?).and_return(false)
    end

    it "doesn't increment the closed_at attribute" do
      expect {
        described_class.perform_now
      }.not_to change {
        petition.reload.closed_at
      }
    end
  end

  context "when signature collection is disabled" do
    context "and extending the closing date doesn't cross a DST boundary" do
      around do |example|
        travel_to("2026-04-01") { example.run }
      end

      before do
        expect(Site).to receive(:signature_collection_disabled?).and_return(true)
      end

      it "increments the closed_at attribute by 24 hours" do
        expect {
          described_class.perform_now
        }.to change {
          petition.reload.closed_at
        }.by(24.hours)
      end
    end

    context "and extending the closing date crosses the autumn DST boundary" do
      around do |example|
        travel_to("2026-04-24") { example.run }
      end

      before do
        expect(Site).to receive(:signature_collection_disabled?).and_return(true)
      end

      it "increments the closed_at attribute by 25 hours" do
        expect {
          described_class.perform_now
        }.to change {
          petition.reload.closed_at
        }.by(25.hours)
      end
    end

    context "and extending the closing date crosses the spring DST boundary" do
      around do |example|
        travel_to("2026-09-27") { example.run }
      end

      before do
        expect(Site).to receive(:signature_collection_disabled?).and_return(true)
      end

      it "increments the closed_at attribute by 23 hours" do
        expect {
          described_class.perform_now
        }.to change {
          petition.reload.closed_at
        }.by(23.hours)
      end
    end
  end
end
