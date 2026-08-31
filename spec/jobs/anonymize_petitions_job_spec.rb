require 'rails_helper'

RSpec.describe AnonymizePetitionsJob, type: :job do
  let(:scheduled_time) { Date.tomorrow.beginning_of_day.iso8601 }

  around do |example|
    travel_to(now) { example.run }
  end

  context "for a petition completed in the winter" do
    let!(:petition) do
      FactoryBot.create(:completed_petition, completed_at: "2023-12-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-12-28T00:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-12-30T00:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition rejected in the winter" do
    let!(:petition) do
      FactoryBot.create(:rejected_petition, rejected_at: "2023-12-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-12-28T00:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-12-30T00:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change { petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition hidden in the winter" do
    let!(:petition) do
      FactoryBot.create(:hidden_petition, rejected_at: "2023-12-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-12-28T00:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-12-30T00:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change { petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition completed in the summer" do
    let!(:petition) do
      FactoryBot.create(:completed_petition, completed_at: "2023-06-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-06-27T23:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change{ petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-06-29T23:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect{
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change{ petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition rejected in the summer" do
    let!(:petition) do
      FactoryBot.create(:rejected_petition, rejected_at: "2023-06-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-06-27T23:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-06-29T23:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change { petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end

  context "for a petition hidden in the summer" do
    let!(:petition) do
      FactoryBot.create(:hidden_petition, rejected_at: "2023-06-29T10:00:00Z")
    end

    context "and the anonymizing date has not passed" do
      let(:now) { "2024-06-27T23:00:00Z".in_time_zone }

      it "does not change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.not_to change { petition.reload.anonymized? }
      end
    end

    context "and the anonymizing date has passed" do
      let(:now) { "2024-06-29T23:00:00Z".in_time_zone }

      it "does change the petition state" do
        expect {
          perform_enqueued_jobs {
            described_class.perform_later(scheduled_time)
          }
        }.to change { petition.reload.anonymized? }.from(false).to(true)
      end
    end
  end
end
