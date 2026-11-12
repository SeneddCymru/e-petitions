require 'rails_helper'

RSpec.describe PaperSignatures, type: :model do
  let(:petition) { FactoryBot.create(:open_petition) }

  subject { described_class.new(petition, "10.0.1.1") }

  describe "defaults" do
    it "defaults the location code to Wales" do
      expect(subject.location_code).to eq("GB-WLS")
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:signature_count).with_message("Number of signatures must be completed") }

    %w[GB-WLS GB-ENG GB-SCT GB-NIR].each do |location_code|
      it { is_expected.to allow_value(location_code).for(:location_code) }
    end

    %w[GB FR US].each do |location_code|
      it { is_expected.not_to allow_value(location_code).for(:location_code) }
    end

    it { is_expected.to allow_value("1").for(:signature_count) }
    it { is_expected.to allow_value("10000").for(:signature_count) }
    it { is_expected.not_to allow_value("0").for(:signature_count) }
    it { is_expected.not_to allow_value("-1").for(:signature_count) }
    it { is_expected.not_to allow_value("1.5").for(:signature_count) }
    it { is_expected.not_to allow_value("10001").for(:signature_count) }
  end

  describe "#save" do
    context "when the attributes are invalid" do
      subject { described_class.new(petition, "10.0.1.1", signature_count: "") }

      it "returns false" do
        expect(subject.save).to eq(false)
      end

      it "doesn't enqueue a job" do
        expect { subject.save }.not_to have_enqueued_job(AddPaperSignaturesJob)
      end
    end

    context "when the attributes are valid" do
      subject { described_class.new(petition, "10.0.1.1", location_code: "GB-SCT", signature_count: "5") }

      it "returns true" do
        expect(subject.save).to eq(true)
      end

      it "enqueues a job" do
        expect { subject.save }.to have_enqueued_job(AddPaperSignaturesJob).with(petition, "GB-SCT", 5, "10.0.1.1")
      end
    end
  end
end
