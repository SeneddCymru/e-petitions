require 'rails_helper'

RSpec.describe Admin::ModerationController, type: :controller, admin: true do

  describe "logged in" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    let(:petition) do
      FactoryBot.create(:sponsored_petition, :translated,
        creator_attributes: {
          name: "Barry Butler",
          email: "bazbutler@gmail.com"
        },
        sponsor_count: 5,
        moderation_threshold_reached_at: 4.days.ago
      )
    end

    context "update" do
      before { ActionMailer::Base.deliveries.clear }
      let(:patch_options) { {} }

      def do_patch(options = patch_options)
        params = { petition_id: petition.id, save_and_email: "Email petition creator" }.merge(petition: options)
        patch :update, params: params
      end

      context "when no moderation is selected" do
        let(:petition) { FactoryBot.create(:pending_petition) }

        before do
          do_patch moderation: ""
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/petitions/show")
        end

        it "displays an alert" do
          expect(flash[:alert]).to eq("Petition could not be updated - please check the form for errors")
        end
      end

      context "when the petition is not validated" do
        let(:petition) { FactoryBot.create(:pending_petition) }

        it "is unsuccessful" do
          expect {
            do_patch moderation: "approve"
          }.not_to change {
            petition.reload.state
          }.from("pending")
        end
      end

      context "when moderation param is 'approve'" do
        let(:now) { Time.current }
        let(:deliveries) { ActionMailer::Base.deliveries }
        let(:creator_email) { deliveries.select{ |m| m.to == %w[bazbutler@gmail.com] }.last }
        let(:sponsor_email) { deliveries.detect{ |m| m.to == %w[laurapalmer@gmail.com] } }
        let(:pending_email) { deliveries.detect{ |m| m.to == %w[sandyfisher@hotmail.com] } }
        let(:duration) { Site.petition_duration.months }
        let(:closing_date) { (now + duration).end_of_day }
        let!(:sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition, email: "laurapalmer@gmail.com") }
        let!(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition, email: "sandyfisher@hotmail.com") }

        before do
          perform_enqueued_jobs do
            sponsor.validate!
            do_patch moderation: "approve"
            petition.reload
          end
        end

        it "opens the petition" do
          expect(petition.state).to eq(Petition::OPEN_STATE)
        end

        it "sets the open date to now" do
          expect(petition.open_at).to be_within(1.second).of(now)
        end

        it "sets the moderation lag" do
          expect(petition.moderation_lag).to eq(4)
        end

        it "sets the moderated by user" do
          expect(petition.moderated_by).to eq(user)
        end

        it "redirects to the admin show page for the petition page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "sends an email to the petition creator" do
          expect(creator_email).to deliver_to("bazbutler@gmail.com")
          expect(creator_email).to have_subject(/We published your petition “[^"]+”/)
        end

        it "sends an email to validated petition sponsors" do
          expect(sponsor_email).to deliver_to("laurapalmer@gmail.com")
          expect(sponsor_email).to have_subject(/We published the petition “[^"]+” that you supported/)
        end

        it "doesn't send an email to pending petition sponsors" do
          expect(pending_email).to be_nil
        end
      end

      context "when moderation param is 'reject'" do
        let(:rejection_code) { 'duplicate' }
        let(:patch_options) do
          {
            moderation: 'reject',
            rejection: { code: rejection_code, details_en: 'rejection details', details_cy: 'manylion gwrthod' }
          }
        end
        let(:deliveries) { ActionMailer::Base.deliveries }
        let(:creator_email) { deliveries.detect{ |m| m.to == %w[bazbutler@gmail.com] } }
        let(:sponsor_email) { deliveries.detect{ |m| m.to == %w[laurapalmer@gmail.com] } }
        let(:pending_email) { deliveries.detect{ |m| m.to == %w[sandyfisher@hotmail.com] } }
        let!(:sponsor) { FactoryBot.create(:sponsor, :validated, petition: petition, email: "laurapalmer@gmail.com") }
        let!(:pending_sponsor) { FactoryBot.create(:sponsor, :pending, petition: petition, email: "sandyfisher@hotmail.com") }

        before do
          perform_enqueued_jobs do
            do_patch
            petition.reload
          end
        end

        shared_examples_for 'rejecting a petition' do
          let(:now) { Time.current }

          it 'sets the petition state to "rejected"' do
            expect(petition.state).to eq(Petition::REJECTED_STATE)
          end

          it "sets the petition rejected date to now" do
            expect(petition.rejected_at).to be_within(1.second).of(now)
          end

          it "sets the moderation lag" do
            expect(petition.moderation_lag).to eq(4)
          end

          it "sets the moderated by user" do
            expect(petition.moderated_by).to eq(user)
          end

          it 'sets the rejection code to the supplied code' do
            expect(petition.rejection.code).to eq(rejection_code)
          end

          it 'sets the rejection details to the supplied details' do
            expect(petition.rejection.details_en).to eq('rejection details')
            expect(petition.rejection.details_cy).to eq('manylion gwrthod')
          end

          it 'redirects to the admin show page for the petition' do
            expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            expect(creator_email).to deliver_to("bazbutler@gmail.com")
            expect(creator_email.subject).to match(/We rejected your petition “[^"]+”/)
          end

          it "sends an email to validated petition sponsors" do
            expect(sponsor_email).to deliver_to("laurapalmer@gmail.com")
            expect(sponsor_email.subject).to match(/We rejected the petition “[^"]+” that you supported/)
          end

          it "does not send an email to pending petition sponsors" do
            expect(pending_email).to be_nil
          end
        end

        context 'with rejection code of "duplicate"' do
          let(:rejection_code) { 'duplicate' }

          it_behaves_like 'rejecting a petition'
        end

        shared_examples_for 'hiding a petition' do
          let(:now) { Time.current }

          it 'sets the petition state to "hidden"' do
            expect(petition.state).to eq(Petition::HIDDEN_STATE)
          end

          it "sets the petition rejected date to now" do
            expect(petition.rejected_at).to be_within(1.second).of(now)
          end

          it "sets the moderation lag" do
            expect(petition.moderation_lag).to eq(4)
          end

          it 'sets the rejection code to the supplied code' do
            expect(petition.rejection.code).to eq(rejection_code)
          end

          it 'redirects to the admin show page for the petition' do
            expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
          end

          it "sends an email to the petition creator" do
            expect(creator_email).to deliver_to("bazbutler@gmail.com")
            expect(creator_email.subject).to match(/We rejected your petition “[^"]+”/)
          end

          it "sends an email to validated petition sponsors" do
            expect(sponsor_email).to deliver_to("laurapalmer@gmail.com")
            expect(sponsor_email.subject).to match(/We rejected the petition “[^"]+” that you supported/)
          end

          it "does not send an email to pending petition sponsors" do
            expect(pending_email).to be_nil
          end
        end

        context 'with rejection code of "offensive"' do
          let(:rejection_code) { 'offensive' }

          it_behaves_like 'hiding a petition'
        end

        context 'with rejection code of "libellous"' do
          let(:rejection_code) { 'libellous' }

          it_behaves_like 'hiding a petition'
        end

        context 'with no rejection code' do
          let(:rejection_code) { '' }

          it "leaves the state alone, in the DB and in-memory" do
            expect(petition.state).to eq(Petition::SPONSORED_STATE)
            expect(assigns(:petition).state).to eq(Petition::SPONSORED_STATE)
          end

          it "renders the admin petitions show template" do
            expect(response).to be_successful
            expect(response).to render_template 'admin/petitions/show'
          end
        end
      end

      context "when moderation param is 'flag'" do
        let(:email) { ActionMailer::Base.deliveries.last }

        before do
          do_patch moderation: 'flag'
          petition.reload
        end

        it "flags the petition" do
          expect(petition.state).to eq(Petition::FLAGGED_STATE)
        end

        it "does not set the open date" do
          expect(petition.open_at).to be_nil
        end

        it "does not set the rejected date" do
          expect(petition.rejected_at).to be_nil
        end

        it "does not set the moderation lag" do
          expect(petition.moderation_lag).to be_nil
        end

        it "does not set the moderated by user" do
          expect(petition.moderated_by).to be_nil
        end

        it "redirects to the admin show page for the petition page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "does not send an email to the petition creator" do
          expect(email).to be_nil
        end
      end

      context "when moderation param is 'unflag'" do
        let(:email) { ActionMailer::Base.deliveries.last }

        before do
          do_patch moderation: 'unflag'
          petition.reload
        end

        it "unflags the petition" do
          expect(petition.state).to eq(Petition::SPONSORED_STATE)
        end

        it "does not set the open date" do
          expect(petition.open_at).to be_nil
        end

        it "does not set the rejected date" do
          expect(petition.rejected_at).to be_nil
        end

        it "does not set the moderation lag" do
          expect(petition.moderation_lag).to be_nil
        end

        it "does not set the moderated by user" do
          expect(petition.moderated_by).to be_nil
        end

        it "redirects to the admin show page for the petition page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "does not send an email to the petition creator" do
          expect(email).to be_nil
        end
      end
    end
  end
end
