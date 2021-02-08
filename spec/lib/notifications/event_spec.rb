require 'rails_helper'

RSpec.describe Notifications::Event do
  let(:event) {
    <<~JSON
      {
        "eventType": "#{type}",
        "mail": {
          "timestamp": "2021-02-07T18:30:00.000Z",
          "source": "no-reply@petitions.parliament.scot",
          "sourceArn": "arn:aws:ses:eu-west-2:999999999999:identity/petitions.parliament.scot",
          "sendingAccountId":"999999999999",
          "messageId": "38ffbce2-bcdc-45df-bf89-4d0189b8b106",
          "destination": ["user@example.com"],
          "headersTruncated": false,
          "headers": [
            { "name": "Date", "value": "Sun, 07 Feb 2021 18:30:00 +0000" },
            { "name": "From", "value": "no-reply@petitions.parliament.scot" },
            { "name": "To", "value": "user@example.com" },
            { "name": "Message-ID", "value": "<38ffbce2-bcdc-45df-bf89-4d0189b8b106@10.0.1.1>" },
            { "name": "Subject", "value": "Please confirm your signature" },
            { "name": "MIME-Version", "value": "1.0" },
            { "name": "Content-Type", "value": "text/plain" }
          ],
          "commonHeaders": {
            "from": ["no-reply@petitions.parliament.scot"],
            "date": "Sun, 07 Feb 2021 18:30:00 +0000",
            "to": ["user@example.com"],
            "messageId": "38ffbce2-bcdc-45df-bf89-4d0189b8b106",
            "subject": "Please confirm your signature"
          },
          "tags": {
            "reference": ["f95cae2a-bd92-4899-8294-4a98ab9a6d71"],
            "ses:operation": ["SendTemplatedEmail"],
            "ses:configuration-set": ["spets-test"],
            "ses:source-ip": ["10.0.0.1"],
            "ses:from-domain":["petitions.parliament.scot"],
            "ses:caller-identity":["petitions.parliament.scot"],
            "notification_id":["7ba3cf31-1381-496b-afe5-64740172b319"],
            "ses:outgoing-ip":["192.168.0.1"]
          }
        },
        "#{object}": #{payload}
      }
    JSON
  }

  let(:sns) do
    <<~JSON
      {
        "Type": "Notification",
        "MessageId": "0970e4bb-1236-4e5e-897f-6cdad3d3f6e5",
        "TopicArn": "arn:aws:sns:eu-west-2:999999999999:spets-ses-events-test",
        "Subject": "Amazon SES Email Event Notification",
        "Message": #{JSON.generate(JSON.generate(JSON.parse(event)))},
        "Timestamp": "2021-02-07T18:30:00.000Z",
        "SignatureVersion": "1",
        "Signature": "RG93biB3aXRoIHRoaXMgc29ydCBvZiB0aGluZw==",
        "SigningCertURL": "https://sns.eu-west-2.amazonaws.com/SimpleNotificationService-6b42a1a5b9d6303ffb79d165cdd8af40.pem",
        "UnsubscribeURL": "https://sns.eu-west-2.amazonaws.com/?Action=Unsubscribe&SubscriptionArn=arn:aws:sns:eu-west-2:999999999999:spets-ses-events-test:0970e4bb-1236-4e5e-897f-6cdad3d3f6e5"
      }
    JSON
  end

  shared_examples_for "a notification event" do
    describe ".parse" do
      it "returns an event instance" do
        expect(described_class.parse(sns)).to be_an_instance_of(described_class)
      end
    end

    describe "instance methods" do
      subject { described_class.parse(sns) }

      describe "#message_id" do
        it "returns the id of the email message" do
          expect(subject.message_id).to eq("38ffbce2-bcdc-45df-bf89-4d0189b8b106")
        end
      end

      describe "#timestamp" do
        it "returns the timestamp of the email message" do
          expect(subject.timestamp).to eq(Time.utc(2021, 2, 7, 18, 30, 0))
        end
      end

      describe "#type" do
        it "returns the type of the event" do
          expect(subject.type).to eq(object)
        end
      end

      describe "payload" do
        it "returns the event payload" do
          expect(subject.payload).to match(JSON.parse(payload))
        end
      end
    end
  end

  describe "Delivery" do
    let(:type) { "Delivery" }
    let(:object) { "delivery" }

    let(:payload) do
      <<~JSON
        {
          "timestamp": "2021-02-07T18:30:00.000Z",
          "recipients": ["user@example.com"],
          "smtpResponse": "250 2.6.0 Message received",
          "reportingMTA": "dsn; mta.example.com"
        }
      JSON
    end

    it_behaves_like "a notification event"
  end

  describe "Bounce" do
    let(:type) { "Bounce" }
    let(:object) { "bounce" }

    let(:payload) do
      <<~JSON
        {
          "bounceType": "Permanent",
          "bounceSubType": "General",
          "bouncedRecipients": [
            {
              "emailAddress":"user@example.com",
              "action":"failed",
              "status":"5.1.1",
              "diagnosticCode":"smtp; 550 5.1.1 user unknown"
            }
          ],
          "timestamp": "2021-02-07T18:30:00.000Z",
          "feedbackId": "38ffbce2-bcdc-45df-bf89-4d0189b8b106",
          "reportingMTA": "dsn; mta.example.com"
        }
      JSON
    end

    it_behaves_like "a notification event"
  end

  describe "Complaint" do
    let(:type) { "Complaint" }
    let(:object) { "complaint" }

    let(:payload) do
      <<~JSON
        {
          "complainedRecipients":[
            {
              "emailAddress":"user@example.com"
            }
          ],
          "timestamp": "2021-02-07T18:30:00.000Z",
          "feedbackId": "38ffbce2-bcdc-45df-bf89-4d0189b8b106",
          "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36",
          "complaintFeedbackType": "abuse",
          "arrivalDate": "2021-02-07T18:30:00.000Z"
        }
      JSON
    end

    it_behaves_like "a notification event"
  end

  describe "Reject" do
    let(:type) { "Reject" }
    let(:object) { "reject" }

    let(:payload) do
      <<~JSON
        {
          "reason": "Bad content"
        }
      JSON
    end

    it_behaves_like "a notification event"
  end

  describe "Rendering Failure" do
    let(:type) { "Rendering Failure" }
    let(:object) { "failure" }

    let(:payload) do
      <<~JSON
        {
          "errorMessage": "Attribute 'creator' is not present in the rendering data.",
          "templateName": "0b6bab61-3af8-47ee-84e4-ce249082afac"
        }
      JSON
    end

    it_behaves_like "a notification event"
  end
end
