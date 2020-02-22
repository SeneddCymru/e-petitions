require "rails_helper"

RSpec.describe PetitionMailer, type: :mailer do
  let :creator do
    FactoryBot.build(:validated_signature, name: "Barry Butler", email: "bazbutler@gmail.com", creator: true)
  end

  let :petition do
    FactoryBot.create(:pending_petition,
      creator: creator,
      action: "Allow organic vegetable vans to use red diesel",
      background: "Add vans to permitted users of red diesel",
      additional_details: "To promote organic vegetables"
    )
  end

  let(:pending_signature) { FactoryBot.create(:pending_signature, name: "Alice Smith", email: "alice@example.com", petition: petition) }
  let(:validated_signature) { FactoryBot.create(:validated_signature, name: "Bob Jones", email: "bob@example.com", petition: petition) }
  let(:subject_prefix) { "Senedd Petitions" }

  describe "notifying creator that moderation is delayed" do
    let! :petition do
      FactoryBot.create(:sponsored_petition,
        creator: creator,
        action: "Allow organic vegetable vans to use red diesel",
        background: "Add vans to permitted users of red diesel",
        additional_details: "To promote organic vegetables"
      )
    end

    let(:subject) { "Moderation of your petition is delayed" }
    let(:body) { "Sorry, but moderation of your petition is delayed for reasons." }
    let(:mail) { PetitionMailer.notify_creator_that_moderation_is_delayed(creator, subject, body) }

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject("Moderation of your petition is delayed")
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the change" do
      expect(mail).to have_body_text("Sorry, but moderation of your petition is delayed for reasons.")
    end
  end

  describe "notifying creator of publication" do
    let(:mail) { PetitionMailer.notify_creator_that_petition_is_published(creator) }

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published your petition “Allow organic vegetable vans to use red diesel”')
    end

    it "is addressed to the creator" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "informs the creator of the publication" do
      expect(mail).to have_body_text("We published the petition you created")
    end
  end

  describe "notifying sponsor of publication" do
    let(:mail) { PetitionMailer.notify_sponsor_that_petition_is_published(sponsor) }
    let(:sponsor) do
      FactoryBot.create(:validated_signature,
        name: "Laura Palmer",
        email: "laura@red-room.example.com",
        petition: petition
      )
    end

    before do
      petition.publish
    end

    it "is sent to the right address" do
      expect(mail.to).to eq(%w[laura@red-room.example.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "has an appropriate subject heading" do
      expect(mail).to have_subject('We published the petition “Allow organic vegetable vans to use red diesel” that you supported')
    end

    it "is addressed to the sponsor" do
      expect(mail).to have_body_text("Dear Laura Palmer,")
    end

    it "informs the sponsor of the publication" do
      expect(mail).to have_body_text("We published the petition you supported")
    end
  end

  describe "notifying creator of rejection" do
    let(:mail) { PetitionMailer.notify_creator_that_petition_was_rejected(creator) }

    context "when rejecting for normal reasons" do
      before do
        petition.reject(code: "duplicate")
      end

      it "is sent to the right address" do
        expect(mail.to).to eq(%w[bazbutler@gmail.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "has an appropriate subject heading" do
        expect(mail).to have_subject('We rejected your petition “Allow organic vegetable vans to use red diesel”')
      end

      it "is addressed to the creator" do
        expect(mail).to have_body_text("Dear Barry Butler,")
      end

      it "informs the creator of the rejection" do
        expect(mail).to have_body_text("We rejected the petition you created")
      end
    end

    context "when there are further details" do
      before do
        petition.reject(code: "irrelevant", details: "Please stop trolling us" )
      end

      it "includes those details in the email" do
        expect(mail).to have_body_text("Please stop trolling us")
      end
    end

    context "when rejecting for reason that cause the petition to be hidden" do
      before do
        petition.reject(code: "offensive")
      end

      it "doesn't include a link to the petition" do
        expect(mail).not_to have_body_text("Click this link to see the rejected petition")
      end
    end
  end

  describe "notifying sponsor of rejection" do
    let(:mail) { PetitionMailer.notify_sponsor_that_petition_was_rejected(sponsor) }
    let(:sponsor) do
      FactoryBot.create(:validated_signature,
        name: "Laura Palmer",
        email: "laura@red-room.example.com",
        petition: petition
      )
    end

    context "when rejecting for normal reasons" do
      before do
        petition.reject(code: "duplicate")
      end

      it "is sent to the right address" do
        expect(mail.to).to eq(%w[laura@red-room.example.com])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "has an appropriate subject heading" do
        expect(mail).to have_subject('We rejected the petition “Allow organic vegetable vans to use red diesel” that you supported')
      end

      it "is addressed to the sponsor" do
        expect(mail).to have_body_text("Dear Laura Palmer,")
      end

      it "informs the sponsor of the publication" do
        expect(mail).to have_body_text("We rejected the petition you supported")
      end
    end

    context "when there are further details" do
      before do
        petition.reject(code: "irrelevant", details: "Please stop trolling us" )
      end

      it "includes those details in the email" do
        expect(mail).to have_body_text("Please stop trolling us")
      end
    end

    context "when rejecting for reason that cause the petition to be hidden" do
      before do
        petition.reject(code: "offensive")
      end

      it "doesn't include a link to the petition" do
        expect(mail).not_to have_body_text("Click this link to see the rejected petition")
      end
    end
  end

  describe "gathering sponsors for petition" do
    subject(:mail) { described_class.gather_sponsors_for_petition(petition) }

    it "has the correct subject" do
      expect(mail).to have_subject(%{Action required: Petition “Allow organic vegetable vans to use red diesel”})
    end

    it "has the addresses the creator by name" do
      expect(mail).to have_body_text("Dear Barry Butler,")
    end

    it "sends it only to the petition creator" do
      expect(mail.to).to eq(%w[bazbutler@gmail.com])
      expect(mail.cc).to be_blank
      expect(mail.bcc).to be_blank
    end

    it "includes a link to pass on to potential sponsors to have them support the petition" do
      expect(mail).to have_body_text(%r[https://petition.senedd.wales/petitions/#{petition.id}/sponsors/new\?token=#{petition.sponsor_token}])
    end

    it "includes the petition action" do
      expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
    end

    it "includes the petition background" do
      expect(mail).to have_body_text(%r[Add vans to permitted users of red diesel])
    end

    it "includes the petition additional details" do
      expect(mail).to have_body_text(%r[To promote organic vegetables])
    end

    it "includes information about moderation" do
      expect(mail).to have_body_text(%r[Once you’ve gained the required number of supporters])
    end

    context "during Christmas" do
      before do
        allow(Holiday).to receive(:christmas?).and_return(true)
      end

      it "includes information about delayed moderation" do
        expect(mail).to have_body_text(%r[but over the Christmas period it will take us a little longer])
      end
    end

    context "during Easter" do
      before do
        allow(Holiday).to receive(:easter?).and_return(true)
      end

      it "includes information about delayed moderation" do
        expect(mail).to have_body_text(%r[but over the Easter period it will take us a little longer])
      end
    end

    context "when there's isn't a moderation delay" do
      let(:scope) { double(Petition) }

      before do
        allow(Petition).to receive(:in_moderation).and_return(scope)
        allow(scope).to receive(:count).and_return(499)
      end

      it "doesn't include information about delayed moderation" do
        expect(mail).not_to have_body_text(%r[however we have a very large number to check])
      end
    end

    context "when there's a moderation delay" do
      let(:scope) { double(Petition) }

      before do
        allow(Petition).to receive(:in_moderation).and_return(scope)
        allow(scope).to receive(:count).and_return(500)
      end

      it "includes information about delayed moderation" do
        expect(mail).to have_body_text(%r[however we have a very large number to check])
      end
    end

    context "when a BCC address is passed" do
      subject(:mail) { described_class.gather_sponsors_for_petition(petition, Site.feedback_email) }

      it "adds the BCC address to the email" do
        expect(mail).to bcc_to("petitions@senedd.wales")
      end
    end
  end

  describe "notifying signature of debate outcome" do
    context "when the signature is the creator" do
      let(:signature) { petition.creator }
      subject(:mail) { described_class.notify_creator_of_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Barry Butler,")
        end

        it "sends it only to the creator" do
          expect(mail.to).to eq(%w[bazbutler@gmail.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.senedd.wales/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Senedd debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Senedd debated your petition")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject('Senedd didn’t debate “Allow organic vegetable vans to use red diesel”')
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate your petition")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryBot.create(:debate_outcome, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryBot.create(:debate_outcome,
              debated_on: "2015-09-24",
              overview: "Debate on Petition P-05-869: Declare a Climate Emergency and fit all policies with zero-carbon targets",
              transcript_url: "https://record.assembly.wales/Plenary/5667#A51756",
              video_url: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
              debate_pack_url: "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Debate on Petition P-05-869: Declare a Climate Emergency and fit all policies with zero-carbon targets])
          end

          it "includes a link to the transcript of the debate" do
            expect(mail).to have_body_text(%r[https://record.assembly.wales/Plenary/5667#A51756])
          end

          it "includes a link to the video of the debate" do
            expect(mail).to have_body_text(%r[http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c\?autostart=True])
          end
        end
      end

      context "when the debate outcome is negative" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryBot.create(:debate_outcome, debated: false, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryBot.create(:debate_outcome,
              debated: false,
              overview: "Discussion of the 2015 Christmas Adjournment",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end
        end
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.notify_signer_of_debate_outcome(petition, signature) }

      shared_examples_for "a debate outcome email" do
        it "addresses the signatory by name" do
          expect(mail).to have_body_text("Dear Laura Palmer,")
        end

        it "sends it only to the signatory" do
          expect(mail.to).to eq(%w[laura@red-room.example.com])
          expect(mail.cc).to be_blank
          expect(mail.bcc).to be_blank
        end

        it "includes a link to the petition page" do
          expect(mail).to have_body_text(%r[https://petition.senedd.wales/petitions/#{petition.id}])
        end

        it "includes the petition action" do
          expect(mail).to have_body_text(%r[Allow organic vegetable vans to use red diesel])
        end

        it "includes an unsubscribe link" do
          expect(mail).to have_body_text(%r[https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
        end

        it "has a List-Unsubscribe header" do
          expect(mail).to have_header("List-Unsubscribe", "<https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
        end
      end

      shared_examples_for "a positive debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Senedd debated “Allow organic vegetable vans to use red diesel”")
        end

        it "has the positive message in the body" do
          expect(mail).to have_body_text("Senedd debated the petition you signed")
        end
      end

      shared_examples_for "a negative debate outcome email" do
        it "has the correct subject" do
          expect(mail).to have_subject("Senedd didn’t debate “Allow organic vegetable vans to use red diesel”")
        end

        it "has the negative message in the body" do
          expect(mail).to have_body_text("The Petitions Committee decided not to debate the petition you signed")
        end
      end

      context "when the debate outcome is positive" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryBot.create(:debate_outcome, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryBot.create(:debate_outcome,
              debated_on: "2015-09-24",
              overview: "Discussion of the 2015 Christmas Adjournment",
              transcript_url: "https://record.assembly.wales/Plenary/5667#A51756",
              video_url: "http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True",
              debate_pack_url: "http://www.senedd.assembly.wales/ieListDocuments.aspx?CId=401&MId=5667",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a positive debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end

          it "includes a link to the transcript of the debate" do
            expect(mail).to have_body_text(%r[https://record.assembly.wales/Plenary/5667#A51756])
          end

          it "includes a link to the video of the debate" do
            expect(mail).to have_body_text(%r[http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c\?autostart=True])
          end
        end
      end

      context "when the debate outcome is negative" do
        context "when the debate outcome is not filled out" do
          before do
            FactoryBot.create(:debate_outcome, debated: false, petition: petition)
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"
        end

        context "when the debate outcome is filled out" do
          before do
            FactoryBot.create(:debate_outcome,
              debated: false,
              overview: "Discussion of the 2015 Christmas Adjournment",
              petition: petition
            )
          end

          it_behaves_like "a debate outcome email"
          it_behaves_like "a negative debate outcome email"

          it "includes the debate outcome overview" do
            expect(mail).to have_body_text(%r[Discussion of the 2015 Christmas Adjournment])
          end
        end
      end
    end
  end

  describe "notifying signature of debate scheduled" do
    let(:petition) { FactoryBot.create(:open_petition, :scheduled_for_debate, creator_attributes: { name: "Bob Jones", email: "bob@jones.com" }, action: "Allow organic vegetable vans to use red diesel") }

    shared_examples_for "a debate scheduled email" do
      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear #{signature.name},")
      end

      it "sends it only to the signatory" do
        expect(mail.to).to eq([signature.email])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.senedd.wales/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end
    end

    context "when the signature is the creator" do
      let(:signature) { petition.creator }
      subject(:mail) { described_class.notify_creator_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "has the correct subject" do
        expect(mail).to have_subject("Senedd will debate “Allow organic vegetable vans to use red diesel”")
      end

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[Senedd is going to debate your petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.notify_signer_of_debate_scheduled(petition, signature) }

      it_behaves_like "a debate scheduled email"

      it "has the correct subject" do
        expect(mail).to have_subject("Senedd will debate “Allow organic vegetable vans to use red diesel”")
      end

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[Senedd is going to debate the petition you signed])
      end
    end
  end

  describe "emailing a signature" do
    let(:petition) { FactoryBot.create(:open_petition, :scheduled_for_debate, creator_attributes: { name: "Bob Jones", email: "bob@jones.com" }, action: "Allow organic vegetable vans to use red diesel") }
    let(:email) { FactoryBot.create(:petition_email, petition: petition, subject: "This is a message from the committee", body: "Message body from the petition committee") }

    shared_examples_for "a petition email" do
      it "has the correct subject" do
        expect(mail).to have_subject("This is a message from the committee")
      end

      it "addresses the signatory by name" do
        expect(mail).to have_body_text("Dear #{signature.name},")
      end

      it "sends it only to the signatory" do
        expect(mail.to).to eq([signature.email])
        expect(mail.cc).to be_blank
        expect(mail.bcc).to be_blank
      end

      it "includes a link to the petition page" do
        expect(mail).to have_body_text(%r[https://petition.senedd.wales/petitions/#{petition.id}])
      end

      it "includes an unsubscribe link" do
        expect(mail).to have_body_text(%r[https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe\?token=#{signature.unsubscribe_token}])
      end

      it "has a List-Unsubscribe header" do
        expect(mail).to have_header("List-Unsubscribe", "<https://petition.senedd.wales/signatures/#{signature.id}/unsubscribe?token=#{signature.unsubscribe_token}>")
      end

      it "includes the message body" do
        expect(mail).to have_body_text(%r[Message body from the petition committee])
      end
    end

    context "when the signature is the creator" do
      let(:signature) { petition.creator }
      subject(:mail) { described_class.email_creator(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as the creator" do
        expect(mail).to have_body_text(%[You recently created the petition])
      end
    end

    context "when the signature is not the creator" do
      let(:signature) { FactoryBot.create(:validated_signature, petition: petition, name: "Laura Palmer", email: "laura@red-room.example.com") }
      subject(:mail) { described_class.email_signer(petition, signature, email) }

      it_behaves_like "a petition email"

      it "identifies them as a ordinary signature" do
        expect(mail).to have_body_text(%[You recently signed the petition])
      end
    end
  end
end
