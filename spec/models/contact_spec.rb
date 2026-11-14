require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe "associations" do
    it { should belong_to(:signature) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_length_of(:address).is_at_most(500) }
    it { is_expected.not_to allow_value(?6 * 32).for(:phone_number).with_message(:too_long) }
  end

  describe "instance methods" do
    describe "#phone_number=" do
      it "normalizes input" do
        expect {
          subject.phone_number = "(0300) 200 6565"
        }.to change {
          subject.phone_number
        }.from(nil).to("0300 200 6565")
      end
    end

    describe "#anonymized?" do
      context "when the contact has not been anonymized" do
        subject { described_class.new(anonymized_at: nil) }

        it "returns false" do
          expect(subject.anonymized?).to eq(false)
        end
      end

      context "when the contact has been anonymized" do
        subject { described_class.new(anonymized_at: 1.day.ago) }

        it "returns false" do
          expect(subject.anonymized?).to eq(true)
        end
      end
    end

    describe "#anonymize" do
      let(:timestamp) { Time.current.beginning_of_day }
      let(:contact) { FactoryBot.build(:contact) }

      it "anonymizes the address" do
        expect {
          contact.anonymize!(timestamp)
        }.to change {
          contact.address
        }.from("Pierhead St, Cardiff").to("Cardiff Bay, Cardiff")
      end

      it "anonymizes the phone number" do
        expect {
          contact.anonymize!(timestamp)
        }.to change {
          contact.phone_number
        }.from("0300 200 6565").to("029 2018 1234")
      end

      it "records the date/time of the anonymization" do
        expect {
          contact.anonymize!(timestamp)
        }.to change {
          contact.anonymized_at
        }.from(nil).to(timestamp)
      end
    end
  end
end
