require 'rails_helper'

RSpec.describe Admin::DebateOutcomesController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:closed_petition) }

  describe 'not logged in' do
    describe 'GET /show' do
      it 'redirects to the login page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petitions.senedd.wales/admin/login')
      end
    end

    describe 'PATCH /update' do
      it 'redirects to the login page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to('https://moderate.petitions.senedd.wales/admin/login')
      end
    end
  end

  context 'logged in as moderator user but need to reset password' do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe 'GET /show' do
      it 'redirects to edit profile page' do
        get :show, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe 'PATCH /update' do
      it 'redirects to edit profile page' do
        patch :update, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe 'GET /show' do
      describe 'for a closed petition' do
        it 'fetches the requested petition' do
          get :show, params: { petition_id: petition.id }
          expect(assigns(:petition)).to eq petition
        end

        context 'that does not already have a debate outcome' do
          it 'exposes an new unsaved debate_outcome for the requested petition' do
            get :show, params: { petition_id: petition.id }
            expect(assigns(:debate_outcome)).to be_present
            expect(assigns(:debate_outcome)).not_to be_persisted
            expect(assigns(:debate_outcome).petition).to eq petition
          end
        end

        context 'that already has a debate outcome' do
          let!(:debate_outcome) { FactoryBot.create(:debate_outcome, petition: petition) }
          it 'exposes the existing debate_outcome on the requested petition' do
            get :show, params: { petition_id: petition.id }
            expect(assigns(:debate_outcome)).to be_present
            expect(assigns(:debate_outcome)).to eq debate_outcome
          end
        end

        it 'responds successfully and renders the petitions/show template' do
          get :show, params: { petition_id: petition.id }
          expect(response).to be_successful
          expect(response).to render_template('petitions/show')
        end
      end

      shared_examples_for 'trying to view a debate outcome for a petition in the wrong state' do
        it 'raises a 404 error' do
          expect {
            get :show, params: { petition_id: petition.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe 'for a pending petition' do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a validated petition' do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a sponsored petition' do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a rejected petition' do
        before { petition.update_columns(state: Petition::REJECTED_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end

      describe 'for a hidden petition' do
        before { petition.update_column(:state, Petition::HIDDEN_STATE) }
        it_behaves_like 'trying to view a debate outcome for a petition in the wrong state'
      end
    end

    describe 'PATCH /update' do
      let(:debate_outcome_attributes) do
        {
          debated_on: '2014-12-01',
          overview_en: 'Debate on Petition P-05-869: Declare a Climate Emergency and fit all policies with zero-carbon targets',
          overview_cy: 'Dadl ar Ddeiseb P-05-869: Datgan Argyfwng Hinsawdd a gosod targedau di-garbon ar bob polisi',
          transcript_url_en: 'https://record.assembly.wales/Plenary/5667#A51756',
          transcript_url_cy: 'https://cofnod.cynulliad.cymru/Plenary/5667#A51756',
          video_url_en: 'http://www.senedd.tv/Meeting/Archive/760dfc2e-74aa-4fc7-b4a7-fccaa9e2ba1c?autostart=True',
          video_url_cy: 'http://www.senedd.tv/Meeting/Archive/c36fbd6a-d3b8-40dd-9567-ac1bef6caa84?autostart=True',
          debate_pack_url_en: "https://business.senedd.wales/ieListDocuments.aspx?CId=401&MId=5667",
          debate_pack_url_cy: "https://busnes.senedd.cymru/ieListDocuments.aspx?CId=401&MId=5667"
        }
      end

      context 'when clicking the Email button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            debate_outcome: debate_outcome_attributes,
            save_and_email: "Email"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'for a closed petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}"
            end

            it 'tells the moderator that their email will be sent overnight' do
              do_patch
              expect(flash[:notice]).to eq 'Email will be sent overnight'
            end

            it 'stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_present
              expect(petition.debate_outcome.debated_on).to eq debate_outcome_attributes[:debated_on].to_date
              expect(petition.debate_outcome.overview_en).to eq debate_outcome_attributes[:overview_en]
              expect(petition.debate_outcome.overview_cy).to eq debate_outcome_attributes[:overview_cy]
              expect(petition.debate_outcome.transcript_url_en).to eq debate_outcome_attributes[:transcript_url_en]
              expect(petition.debate_outcome.transcript_url_cy).to eq debate_outcome_attributes[:transcript_url_cy]
              expect(petition.debate_outcome.video_url_en).to eq debate_outcome_attributes[:video_url_en]
              expect(petition.debate_outcome.video_url_cy).to eq debate_outcome_attributes[:video_url_cy]
              expect(petition.debate_outcome.debate_pack_url_en).to eq debate_outcome_attributes[:debate_pack_url_en]
              expect(petition.debate_outcome.debate_pack_url_cy).to eq debate_outcome_attributes[:debate_pack_url_cy]
            end

            describe "emails out a debate outcome response" do
              before do
                3.times do |i|
                  attributes = {
                    name: "Laura #{i}",
                    email: "laura_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  s = FactoryBot.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Sarah #{i}",
                    email: "sarah_#{i}@example.com",
                    notify_by_email: false,
                    petition: petition
                  }

                  s = FactoryBot.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Brian #{i}",
                    email: "brian_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  FactoryBot.create(:pending_signature, attributes)
                end
                petition.reload
              end

              it "queues a job to process the emails" do
                assert_enqueued_jobs 1 do
                  do_patch
                end
              end

              it "stamps the 'debate_outcome' email sent timestamp on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_patch
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for('debate_outcome')
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.subscribed.each do |signature|
                    expect(signature.get_email_sent_at_for('debate_outcome')).to eq(petition_timestamp)
                  end
                end
              end

              it "should email out to the validated signees who have opted in when the delayed job runs" do
                ActionMailer::Base.deliveries.clear
                perform_enqueued_jobs do
                  do_patch
                  expect(ActionMailer::Base.deliveries.length).to eq 4
                  expect(ActionMailer::Base.deliveries.map(&:to)).to eq([
                    [petition.creator.email],
                    ['laura_0@example.com'],
                    ['laura_1@example.com'],
                    ['laura_2@example.com']
                  ])
                end
              end
            end
          end

          shared_examples_for 'a debate_outcome with invalid parameters' do
            it 're-renders the petitions/show template' do
              do_patch
              expect(response).to be_successful
              expect(response).to render_template('petitions/show')
            end

            it 'leaves the in-memory instance with errors' do
              do_patch
              expect(assigns(:petition).debate_outcome).to be_present
              expect(assigns(:petition).debate_outcome.errors).not_to be_empty
            end

            it 'does not stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_nil
            end
          end

          describe 'with invalid params' do
            before { debate_outcome_attributes.delete(:debated_on) }
            it_behaves_like 'a debate_outcome with invalid parameters'
          end

          describe 'image handling' do
            def patch_and_reload
              do_patch
              petition.reload
            end

            describe 'a valid image' do
              before { debate_outcome_attributes[:image] = fixture_file_upload('debate_outcome/commons_image-2x.jpg') }
              before { patch_and_reload }

              it 'attaches the image' do
                expect(petition.debate_outcome.image).to be_attached
              end
            end

            describe 'a non-image' do
              before { debate_outcome_attributes[:image] = fixture_file_upload('debate_outcome/commons_image-2x.txt') }
              it_behaves_like 'a debate_outcome with invalid parameters'
            end

            describe 'a non-JPEG image' do
              before { debate_outcome_attributes[:image] = fixture_file_upload('debate_outcome/commons_image-2x.png') }
              it_behaves_like 'a debate_outcome with invalid parameters'
            end

            describe 'a small image' do
              before { debate_outcome_attributes[:image] = fixture_file_upload('debate_outcome/commons_image-too-short.jpg') }
              it_behaves_like 'a debate_outcome with invalid parameters'
            end

            describe 'an image in the wrong ratio' do
              before { debate_outcome_attributes[:image] = fixture_file_upload('debate_outcome/commons_image-incorrect-ratio.jpg') }
              it_behaves_like 'a debate_outcome with invalid parameters'
            end
          end
        end

        shared_examples_for 'trying to add debate outcome details to a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not stores the supplied debate outcome details in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(petition.debate_outcome).to be_nil
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end
      end

      context 'when clicking the Save button' do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            debate_outcome: debate_outcome_attributes,
            save: "Save"
          }

          patch :update, params: params.merge(overrides)
        end

        describe 'for a closed petition' do
          it 'fetches the requested petition' do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          describe 'with valid params' do
            it 'redirects to the petition show page' do
              do_patch
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}"
            end

            it 'tells the moderator that their changes were saved' do
              do_patch
              expect(flash[:notice]).to eq 'Updated debate outcome successfully'
            end

            it 'stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_present
              expect(petition.debate_outcome.debated_on).to eq debate_outcome_attributes[:debated_on].to_date
              expect(petition.debate_outcome.overview_en).to eq debate_outcome_attributes[:overview_en]
              expect(petition.debate_outcome.overview_cy).to eq debate_outcome_attributes[:overview_cy]
              expect(petition.debate_outcome.transcript_url_en).to eq debate_outcome_attributes[:transcript_url_en]
              expect(petition.debate_outcome.transcript_url_cy).to eq debate_outcome_attributes[:transcript_url_cy]
              expect(petition.debate_outcome.video_url_en).to eq debate_outcome_attributes[:video_url_en]
              expect(petition.debate_outcome.video_url_cy).to eq debate_outcome_attributes[:video_url_cy]
              expect(petition.debate_outcome.debate_pack_url_en).to eq debate_outcome_attributes[:debate_pack_url_en]
              expect(petition.debate_outcome.debate_pack_url_cy).to eq debate_outcome_attributes[:debate_pack_url_cy]
            end

            describe "does not email out debate outcome response" do
              before do
                3.times do |i|
                  attributes = {
                    name: "Laura #{i}",
                    email: "laura_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  s = FactoryBot.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Sarah #{i}",
                    email: "sarah_#{i}@example.com",
                    notify_by_email: false,
                    petition: petition
                  }

                  s = FactoryBot.create(:pending_signature, attributes)
                  s.validate!
                end
                2.times do |i|
                  attributes = {
                    name: "Brian #{i}",
                    email: "brian_#{i}@example.com",
                    notify_by_email: true,
                    petition: petition
                  }
                  FactoryBot.create(:pending_signature, attributes)
                end
                petition.reload
              end

              it "does not queue a job to process the emails" do
                assert_enqueued_jobs 0 do
                  do_patch
                end
              end
            end
          end

          describe 'with invalid params' do
            before { debate_outcome_attributes.delete(:debated_on) }

            it 're-renders the petitions/show template' do
              do_patch
              expect(response).to be_successful
              expect(response).to render_template('petitions/show')
            end

            it 'leaves the in-memory instance with errors' do
              do_patch
              expect(assigns(:petition).debate_outcome).to be_present
              expect(assigns(:petition).debate_outcome.errors).not_to be_empty
            end

            it 'does not stores the supplied debate outcome details in the db' do
              do_patch
              petition.reload
              expect(petition.debate_outcome).to be_nil
            end
          end
        end

        shared_examples_for 'trying to add debate outcome details to a petition in the wrong state' do
          it 'raises a 404 error' do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it 'does not stores the supplied debate outcome details in the db' do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            petition.reload
            expect(petition.debate_outcome).to be_nil
          end
        end

        describe 'for a pending petition' do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a validated petition' do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a sponsored petition' do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a rejected petition' do
          before { petition.update_columns(state: Petition::REJECTED_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end

        describe 'for a hidden petition' do
          before { petition.update_column(:state, Petition::HIDDEN_STATE) }
          it_behaves_like 'trying to add debate outcome details to a petition in the wrong state'
        end
      end

      context "when two moderators update the debate outcome for the first time simultaneously" do
        let(:debate_outcome) do
          FactoryBot.build(:debate_outcome, overview_en: "", debated: false, petition: petition)
        end

        before do
          debateable = double(:scope)
          allow(Petition).to receive(:debateable).and_return(debateable)
          allow(debateable).to receive(:find).with(petition.id.to_s).and_return(petition)
        end

        it "doesn't raise an ActiveRecord::RecordNotUnique error" do
          expect {
            expect(petition.debate_outcome).to be_nil

            outcome_attributes = {
              overview_en: "overview 1",
              debated: false
            }

            patch :update, params: { petition_id: petition.id, debate_outcome: outcome_attributes, save: "Save" }
            expect(petition.debate_outcome.overview).to eq("overview 1")

            allow(petition).to receive(:debate_outcome).and_return(nil, petition.debate_outcome)
            allow(petition).to receive(:build_debate_outcome).and_return(debate_outcome)

            outcome_attributes = {
              overview_en: "overview 2",
              debated: false
            }

            patch :update, params: { petition_id: petition.id, debate_outcome: outcome_attributes, save: "Save" }
            expect(petition.reload_debate_outcome.overview).to eq("overview 2")
          }.not_to raise_error
        end
      end
    end
  end
end
