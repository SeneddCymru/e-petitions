require 'rails_helper'

RSpec.describe NotifyEveryoneOfModerationDecisionJob, type: :job do
  let!(:petition) { FactoryBot.create(:pending_petition, :translated, sponsor_count: 0, collect_signatures: true) }
  let!(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition) }
  let!(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition) }

  let(:creator) { petition.creator }

  context "when the petition is published" do
    context "and is collecting signatures" do
      before do
        petition.publish
      end

      it "notifies the creator" do
        expect {
          described_class.perform_now(petition)
        }.to have_enqueued_job(
          NotifyCreatorThatPetitionIsPublishedWithSignaturesEmailJob
        ).with(creator).on_queue("high_priority")
      end

      it "notifies the validated sponsors" do
        expect {
          described_class.perform_now(petition)
        }.to have_enqueued_job(
          NotifySponsorThatPetitionIsPublishedWithSignaturesEmailJob
        ).with(validated_sponsor).on_queue("high_priority")
      end

      it "doesn't notify the pending sponsors" do
        expect {
          described_class.perform_now(petition)
        }.not_to have_enqueued_job(
          NotifySponsorThatPetitionIsPublishedWithSignaturesEmailJob
        ).with(pending_sponsor).on_queue("high_priority")
      end
    end

    context "and is not collecting signatures" do
      let(:petition_not_collecting_signatures) { FactoryBot.create(:pending_petition, :translated, sponsor_count: 0, collect_signatures: false) }
      let(:validated_sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition_not_collecting_signatures) }
      let(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition_not_collecting_signatures) }

      let(:creator) { petition_not_collecting_signatures.creator }

      before do
        petition_not_collecting_signatures.publish
      end

      it "notifies the creator" do
        expect {
          described_class.perform_now(petition_not_collecting_signatures)
        }.to have_enqueued_job(
          NotifyCreatorThatPetitionIsPublishedWithoutSignaturesEmailJob
        ).with(creator).on_queue("high_priority")
      end

      it "notifies the validated sponsors" do
        expect {
          described_class.perform_now(petition_not_collecting_signatures)
        }.to have_enqueued_job(
          NotifySponsorThatPetitionIsPublishedWithoutSignaturesEmailJob
        ).with(validated_sponsor).on_queue("high_priority")
      end

      it "doesn't notify the pending sponsors" do
        expect {
          described_class.perform_now(petition_not_collecting_signatures)
        }.not_to have_enqueued_job(
          NotifySponsorThatPetitionIsPublishedWithoutSignaturesEmailJob
        ).with(pending_sponsor).on_queue("high_priority")
      end
    end
  end

  context "when the petition is rejected" do
    let(:rejection) { petition.rejection }

    before do
      petition.reject(code: "duplicate")
    end

    it "notifies the creator" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifyCreatorThatPetitionWasRejectedEmailJob
      ).with(creator, rejection).on_queue("high_priority")
    end

    it "notifies the validated sponsors" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(validated_sponsor, rejection).on_queue("high_priority")
    end

    it "doesn't notify the pending sponsors" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(pending_sponsor, rejection).on_queue("high_priority")
    end
  end

  context "when the petition is hidden" do
    let(:rejection) { petition.rejection }

    before do
      petition.reject(code: "offensive")
    end

    it "notifies the creator" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifyCreatorThatPetitionWasRejectedEmailJob
      ).with(creator, rejection).on_queue("high_priority")
    end

    it "notifies the validated sponsors" do
      expect {
        described_class.perform_now(petition)
      }.to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(validated_sponsor, rejection).on_queue("high_priority")
    end

    it "doesn't notify the pending sponsors" do
      expect {
        described_class.perform_now(petition)
      }.not_to have_enqueued_job(
        NotifySponsorThatPetitionWasRejectedEmailJob
      ).with(pending_sponsor, rejection).on_queue("high_priority")
    end
  end
end
