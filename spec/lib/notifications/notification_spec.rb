require 'rails_helper'

RSpec.describe Notifications::Notification, type: :model do
  let(:aws_region) { "https://email.eu-west-2.amazonaws.com" }
  let(:email_api) { "#{aws_region}/v2/email/outbound-emails" }

  describe "schema" do
    it { is_expected.to have_db_column(:id).of_type(:uuid).with_options(null: false) }
    it { is_expected.to have_db_column(:to).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:template_id).of_type(:uuid).with_options(null: false) }
    it { is_expected.to have_db_column(:reference).of_type(:string).with_options(null: false, limit: 100) }
    it { is_expected.to have_db_column(:message_id).of_type(:string).with_options(limit: 100) }
    it { is_expected.to have_db_column(:personalisation).of_type(:jsonb).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:integer).with_options(null: false, default: "created") }
    it { is_expected.to have_db_column(:events).of_type(:jsonb).with_options(null: false, default: {}) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index(:reference) }
    it { is_expected.to have_db_index(:message_id).unique }
    it { is_expected.to have_db_index(:template_id) }
    it { is_expected.to have_db_index(:status) }
    it { is_expected.to have_db_index(:created_at) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:to) }
    it { is_expected.to validate_presence_of(:reference) }
    it { is_expected.to validate_presence_of(:template_id) }

    it { is_expected.to validate_length_of(:reference).is_at_most(100) }

    it { is_expected.to allow_value("user@example.com").for(:to) }
    it { is_expected.not_to allow_value("user").for(:to) }

    it { is_expected.to allow_value("0a392fa6-9b5f-4685-852c-1f09f78beb54").for(:template_id) }
    it { is_expected.not_to allow_value("template").for(:template_id) }
  end

  describe ".send!" do
    context "when there are invalid keys" do
      it "raises an argument error" do
        expect {
          described_class.send!(secret: "token")
        }.to raise_error(ArgumentError)
      end
    end

    context "when there are missing keys" do
      it "raises a validation error" do
        expect {
          described_class.send!({})
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when the options are valid" do
      let(:options) do
        {
          email_address: "jackie.frasier@example.com",
          template_id: "58d83355-5e19-431f-a750-4479d5cc5cd3",
          reference: "ca2914d0-0519-5aff-b4ab-5bff071cdab2",
          personalisation: { name: "Jackie Frasier" }
        }
      end

      let(:request) do
        hash_including(
          "Destination" => hash_including(
            "ToAddresses" => ["jackie.frasier@example.com"]
          ),
          "Content" => hash_including(
            "Template" => hash_including(
              "TemplateName" => "58d83355-5e19-431f-a750-4479d5cc5cd3"
            )
          )
        )
      end

      let(:message_id) { "ff833ece-3a40-4469-aac3-a566564344ee" }

      let(:successful_response) do
        { status: 200, body: %[{"MessageId":"#{message_id}"}], headers: { "Content-Type" => "application/json" } }
      end

      let(:error_response) do
        { status: 429, body: '{"code":"TooManyRequestsException"}', headers: { "Content-Type" => "application/json" } }
      end

      context "and the EMAIL_CONFIG environment variable is not set" do
        before do
          allow(ENV).to receive(:fetch).and_call_original
          expect(ENV).to receive(:fetch).with("EMAIL_CONFIG").and_raise(KeyError)
        end

        it "raises a not configured error" do
          expect {
            described_class.send!(options)
          }.to raise_error(Notifications::Client::NotConfiguredError)
        end
      end

      context "and the SES request is successful" do
        before do
          stub_request(:post, email_api).with(body: request).to_return(successful_response)
        end

        it "creates a notification record" do
          expect {
            described_class.send!(options)
          }.to change(described_class, :count).from(0).to(1)
        end

        it "updates the notification with the message id" do
          expect {
            described_class.send!(options)
          }.to change {
            described_class.find_by(message_id: message_id)
          }.from(nil).to(an_instance_of(described_class))
        end
      end

      context "and the SES request is unsuccessful" do
        before do
          stub_request(:post, email_api).with(body: request).to_return(error_response)
        end

        it "doesn't create a notification record" do
          expect {
            expect {
              described_class.send!(options)
            }.to raise_error(Aws::SESV2::Errors::TooManyRequestsException)
          }.not_to change(described_class, :count).from(0)
        end
      end
    end
  end

  describe "#payload" do
    let(:notification) do
      FactoryBot.create(:notification,
        id: "6262d8e8-57f9-4fc7-acdc-d8b00bbbafcd",
        to: "user@example.com",
        template_id: "01731224-9a4b-45d7-a802-7d6853b0ab6d",
        reference: "d3932b33-cd80-499b-b071-6ceddb3aeec3",
        personalisation: { foo: "bar" }
      )
    end

    it "generates a hash for the SES SendEmail API" do
      expect(notification.payload).to match(
        from_email_address: Site.email_from,
        destination: { to_addresses: ["user@example.com"] },
        configuration_set_name: "spets-test",
        content: { template: {
          template_name: "01731224-9a4b-45d7-a802-7d6853b0ab6d",
          template_data: '{"foo":"bar"}'
        }},
        email_tags: [
          { name: "reference", value: "d3932b33-cd80-499b-b071-6ceddb3aeec3" },
          { name: "notification_id", value: "6262d8e8-57f9-4fc7-acdc-d8b00bbbafcd" }
        ]
      )
    end
  end
end
