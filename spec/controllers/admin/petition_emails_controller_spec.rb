require 'rails_helper'

RSpec.describe Admin::PetitionEmailsController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:open_petition) }

  context "when not logged in" do
    let(:email) { FactoryBot.create(:petition_email, petition: petition) }

    describe "GET /admin/petitions/:petition_id/emails" do
      it "redirects to the login page" do
        get :index, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/new" do
      it "redirects to the login page" do
        get :new, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "POST /admin/petitions/:petition_id/emails" do
      it "redirects to the login page" do
        post :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/:id/edit" do
      it "redirects to the login page" do
        get :edit, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "PATCH /admin/petitions/:petition_id/emails/:id" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "DELETE /admin/petitions/:petition_id/emails/:id" do
      it "redirects to the login page" do
        patch :destroy, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "logged in as moderator user but the password needs reseting" do
    let(:email) { FactoryBot.create(:petition_email, petition: petition) }
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }

    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/emails" do
      it "redirects to edit profile page" do
        get :index, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/new" do
      it "redirects to edit profile page" do
        get :new, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "POST /admin/petitions/:petition_id/emails/" do
      it "redirects to edit profile page" do
        post :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/:id/edit" do
      it "redirects to the login page" do
        get :edit, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "PATCH /admin/petitions/:petition_id/emails/:id" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "DELETE /admin/petitions/:petition_id/emails/:id" do
      it "redirects to the login page" do
        patch :destroy, params: { petition_id: petition.id, id: email.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/emails" do
      describe "for an open petition" do
        it "fetches the requested petition" do
          get :index, params: { petition_id: petition.id }
          expect(assigns(:petition)).to eq petition
        end

        it "responds successfully and renders the admin/petitions/show template" do
          get :index, params: { petition_id: petition.id }
          expect(response).to be_successful
          expect(response).to render_template("admin/petitions/show")
        end
      end

      shared_examples_for "trying to view the email petitioners form of a petition in the wrong state" do
        it "raises a 404 error" do
          expect {
            get :index, params: { petition_id: petition.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "for a pending petition" do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a validated petition" do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a sponsored petition" do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/new" do
      describe "for an open petition" do
        it "fetches the requested petition" do
          get :new, params: { petition_id: petition.id }
          expect(assigns(:petition)).to eq petition
        end

        it "responds successfully and renders the admin/petition_emails/new template" do
          get :new, params: { petition_id: petition.id }
          expect(response).to be_successful
          expect(response).to render_template("admin/petition_emails/new")
        end
      end

      shared_examples_for "trying to view the email petitioners form of a petition in the wrong state" do
        it "raises a 404 error" do
          expect {
            get :new, params: { petition_id: petition.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "for a pending petition" do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a validated petition" do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a sponsored petition" do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end
    end

    describe "POST /admin/petitions/:petition_id/emails" do
      let(:petition_email_attributes) do
        {
          subject_en: "Petition email subject",
          body_en: "Petition email body",
          subject_cy: "Testun e-bost y ddeiseb",
          body_cy: "Corff e-bost deiseb"
        }
      end

      context "when clicking the Email button" do
        def do_post(overrides = {})
          params = {
            petition_id: petition.id,
            petition_email: petition_email_attributes,
            save_and_email: "Email"
          }

          post :create, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_post
            expect(assigns(:petition)).to eq petition
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_post
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their email will be sent overnight" do
              do_post
              expect(flash[:notice]).to eq "Email will be sent overnight"
            end

            it "stores the supplied email details in the db" do
              do_post
              petition.reload
              email = petition.emails.last
              expect(email).to be_present
              expect(email.subject_en).to eq "Petition email subject"
              expect(email.body_en).to eq "Petition email body"
              expect(email.subject_cy).to eq "Testun e-bost y ddeiseb"
              expect(email.body_cy).to eq "Corff e-bost deiseb"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "emails out the petition email" do
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
                expect {
                  do_post
                }.to have_enqueued_job(EmailPetitionersJob)
              end

              it "queues a job to send a copy to the feedback address" do
                expect {
                  do_post
                }.to have_enqueued_job(EmailSignerAboutOtherBusinessEmailJob)
              end

              it "stamps the 'petition_email' email sent timestamp on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_post
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for("petition_email")
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.subscribed.each do |signature|
                    expect(signature.get_email_sent_at_for("petition_email")).to eq(petition_timestamp)
                  end
                end
              end

              it "should email out to the validated signees who have opted in when the delayed job runs" do
                perform_enqueued_jobs do
                  do_post
                  expect(deliveries.length).to eq 5
                  expect(deliveries.map(&:to)).to eq([
                    [petition.creator.email],
                    ["laura_0@example.com"],
                    ["laura_1@example.com"],
                    ["laura_2@example.com"],
                    ["petitions@senedd.wales"]
                  ])
                end
              end
            end
          end

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/new template" do
              do_post
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/new")
            end

            it "leaves the in-memory instance with errors" do
              do_post
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_post
              petition.reload
              expect(petition.emails).to be_empty
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_post
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not stores the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_post }
            petition.reload
            expect(petition.emails).to be_empty
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end

      context "when clicking the Save button" do
        def do_post(overrides = {})
          params = {
            petition_id: petition.id,
            petition_email: petition_email_attributes,
            save: "Save"
          }

          post :create, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_post
            expect(assigns(:petition)).to eq petition
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_post
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their changes were saved" do
              do_post
              expect(flash[:notice]).to eq "Created other Senedd business successfully"
            end

            it "stores the supplied email details in the db" do
              do_post
              petition.reload
              email = petition.emails.last
              expect(email).to be_present
              expect(email.subject_en).to eq "Petition email subject"
              expect(email.body_en).to eq "Petition email body"
              expect(email.subject_cy).to eq "Testun e-bost y ddeiseb"
              expect(email.body_cy).to eq "Corff e-bost deiseb"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "does not email out the petition email" do
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
                  do_post
                end
              end
            end
          end

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/new template" do
              do_post
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/new")
            end

            it "leaves the in-memory instance with errors" do
              do_post
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_post
              petition.reload
              expect(petition.emails).to be_empty
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_post
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not store the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_post }
            petition.reload
            expect(petition.emails).to be_empty
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end

      context "when clicking the Preview button" do
        def do_post(overrides = {})
          params = {
            petition_id: petition.id,
            petition_email: petition_email_attributes,
            save_and_preview: "Save and preview"
          }

          post :create, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_post
            expect(assigns(:petition)).to eq petition
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_post
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their changes were saved" do
              do_post
              expect(flash[:notice]).to eq "Preview email successfully sent"
            end

            it "stores the supplied email details in the db" do
              do_post
              petition.reload
              email = petition.emails.last
              expect(email).to be_present
              expect(email.subject_en).to eq "Petition email subject"
              expect(email.body_en).to eq "Petition email body"
              expect(email.subject_cy).to eq "Testun e-bost y ddeiseb"
              expect(email.body_cy).to eq "Corff e-bost deiseb"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "does not email out the petition email" do
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

              it "enqueues a job to process the email" do
                expect {
                  do_post
                }.to have_enqueued_job(EmailSignerAboutOtherBusinessEmailJob)
              end
            end
          end

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/new template" do
              do_post
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/new")
            end

            it "leaves the in-memory instance with errors" do
              do_post
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_post
              petition.reload
              expect(petition.emails).to be_empty
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_post
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not store the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_post }
            petition.reload
            expect(petition.emails).to be_empty
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end
    end

    describe "GET /admin/petitions/:petition_id/emails/:id/edit" do
      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "Petition email subject",
          body_en: "Petition email body",
          subject_cy: "Testun e-bost y ddeiseb",
          body_cy: "Corff e-bost deiseb"
        )
      end

      describe "for an open petition" do
        it "fetches the requested petition" do
          get :edit, params: { petition_id: petition.id, id: email.id }
          expect(assigns(:petition)).to eq petition
        end

        it "fetches the requested email" do
          get :edit, params: { petition_id: petition.id, id: email.id }
          expect(assigns(:email)).to eq email
        end

        it "responds successfully and renders the admin/petition_emails/edit template" do
          get :edit, params: { petition_id: petition.id, id: email.id }
          expect(response).to be_successful
          expect(response).to render_template("admin/petition_emails/edit")
        end
      end

      shared_examples_for "trying to view the email petitioners form of a petition in the wrong state" do
        it "raises a 404 error" do
          expect {
            get :new, params: { petition_id: petition.id, id: email.id }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "for a pending petition" do
        before { petition.update_column(:state, Petition::PENDING_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a validated petition" do
        before { petition.update_column(:state, Petition::VALIDATED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end

      describe "for a sponsored petition" do
        before { petition.update_column(:state, Petition::SPONSORED_STATE) }
        it_behaves_like "trying to view the email petitioners form of a petition in the wrong state"
      end
    end

    describe "PATCH /admin/petitions/:petition_id/emails/:id" do
      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject_en: "Petition email subject",
          body_en: "Petition email body",
          subject_cy: "Testun e-bost y ddeiseb",
          body_cy: "Corff e-bost deiseb"
        )
      end

      let(:petition_email_attributes) do
        {
          subject_en: "New petition email subject",
          body_en: "New petition email body",
          subject_cy: "Testun e-bost deiseb newydd",
          body_cy: "Corff e-bost deiseb newydd"
        }
      end

      context "when clicking the Email button" do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            id: email.id,
            petition_email: petition_email_attributes,
            save_and_email: "Email"
          }

          patch :update, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it "fetches the requested email" do
            do_patch
            expect(assigns(:email)).to eq email
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_patch
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their email will be sent overnight" do
              do_patch
              expect(flash[:notice]).to eq "Email will be sent overnight"
            end

            it "stores the supplied email details in the db" do
              do_patch
              petition.reload
              email = petition.emails.last
              expect(email).to be_present
              expect(email.subject_en).to eq "New petition email subject"
              expect(email.body_en).to eq "New petition email body"
              expect(email.subject_cy).to eq "Testun e-bost deiseb newydd"
              expect(email.body_cy).to eq "Corff e-bost deiseb newydd"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "emails out the petition email" do
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
                expect {
                  do_patch
                }.to have_enqueued_job(EmailPetitionersJob)
              end

              it "queues a job to send a copy to the feedback address" do
                expect {
                  do_patch
                }.to have_enqueued_job(EmailSignerAboutOtherBusinessEmailJob)
              end

              it "stamps the 'petition_email' email sent timestamp on each signature when the job runs" do
                perform_enqueued_jobs do
                  do_patch
                  petition.reload
                  petition_timestamp = petition.get_email_requested_at_for("petition_email")
                  expect(petition_timestamp).not_to be_nil
                  petition.signatures.validated.subscribed.each do |signature|
                    expect(signature.get_email_sent_at_for("petition_email")).to eq(petition_timestamp)
                  end
                end
              end

              it "should email out to the validated signees who have opted in when the delayed job runs" do
                perform_enqueued_jobs do
                  do_patch
                  expect(deliveries.length).to eq 5
                  expect(deliveries.map(&:to)).to eq([
                    [petition.creator.email],
                    ["laura_0@example.com"],
                    ["laura_1@example.com"],
                    ["laura_2@example.com"],
                    ["petitions@senedd.wales"]
                  ])
                end
              end
            end
          end

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/edit template" do
              do_patch
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/edit")
            end

            it "leaves the in-memory instance with errors" do
              do_patch
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_patch
              email.reload
              expect(email).to be_present
              expect(email.subject).to eq "Petition email subject"
              expect(email.body).to eq "Petition email body"
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not stores the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            email.reload
            expect(email).to be_present
            expect(email.subject).to eq "Petition email subject"
            expect(email.body).to eq "Petition email body"
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end

      context "when clicking the Save button" do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            id: email.id,
            petition_email: petition_email_attributes,
            save: "Save"
          }

          patch :update, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it "fetches the requested email" do
            do_patch
            expect(assigns(:email)).to eq email
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_patch
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their changes were saved" do
              do_patch
              expect(flash[:notice]).to eq "Updated other Senedd business successfully"
            end

            it "stores the supplied email details in the db" do
              do_patch
              email.reload
              expect(email).to be_present
              expect(email.subject).to eq "New petition email subject"
              expect(email.body).to eq "New petition email body"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "does not email out the petition email" do
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

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/edit template" do
              do_patch
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/edit")
            end

            it "leaves the in-memory instance with errors" do
              do_patch
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_patch
              email.reload
              expect(email.subject).to eq("Petition email subject")
              expect(email.body).to eq("Petition email body")
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not store the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            email.reload
            expect(email.subject).to eq("Petition email subject")
            expect(email.body).to eq("Petition email body")
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end

      context "when clicking the Preview button" do
        def do_patch(overrides = {})
          params = {
            petition_id: petition.id,
            id: email.id,
            petition_email: petition_email_attributes,
            save_and_preview: "Save and preview"
          }

          patch :update, params: params.merge(overrides)
        end

        describe "for an open petition" do
          it "fetches the requested petition" do
            do_patch
            expect(assigns(:petition)).to eq petition
          end

          it "fetches the requested email" do
            do_patch
            expect(assigns(:email)).to eq email
          end

          describe "with valid params" do
            it "redirects to the petition emails page" do
              do_patch
              expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
            end

            it "tells the moderator that their changes were saved" do
              do_patch
              expect(flash[:notice]).to eq "Preview email successfully sent"
            end

            it "stores the supplied email details in the db" do
              do_patch
              email.reload
              expect(email).to be_present
              expect(email.subject).to eq "New petition email subject"
              expect(email.body).to eq "New petition email body"
              expect(email.sent_by).to eq user.pretty_name
            end

            context "does not email out the petition email" do
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

              it "enqueues a job to process the email" do
                expect {
                  do_patch
                }.to have_enqueued_job(EmailSignerAboutOtherBusinessEmailJob)
              end
            end

            it "should email out a preview email" do
              perform_enqueued_jobs do
                do_patch
                expect(deliveries.length).to eq 1
                expect(deliveries.map(&:to)).to eq([
                  ["petitions@senedd.wales"]
                ])
              end
            end
          end

          describe "with invalid params" do
            let(:petition_email_attributes) do
              { subject_en: "", body_en: "", subject_cy: "", body_cy: "" }
            end

            it "re-renders the admin/petition_emails/edit template" do
              do_patch
              expect(response).to be_successful
              expect(response).to render_template("admin/petition_emails/edit")
            end

            it "leaves the in-memory instance with errors" do
              do_patch
              expect(assigns(:email)).to be_present
              expect(assigns(:email).errors).not_to be_empty
            end

            it "does not stores the email details in the db" do
              do_patch
              email.reload
              expect(email.subject_en).to eq "Petition email subject"
              expect(email.body_en).to eq "Petition email body"
              expect(email.subject_cy).to eq "Testun e-bost y ddeiseb"
              expect(email.body_cy).to eq "Corff e-bost deiseb"
            end
          end
        end

        shared_examples_for "trying to email supporters of a petition in the wrong state" do
          it "raises a 404 error" do
            expect {
              do_patch
            }.to raise_error ActiveRecord::RecordNotFound
          end

          it "does not store the supplied email details in the db" do
            suppress(ActiveRecord::RecordNotFound) { do_patch }
            email.reload
            expect(email.subject).to eq("Petition email subject")
            expect(email.body).to eq("Petition email body")
          end
        end

        describe "for a pending petition" do
          before { petition.update_column(:state, Petition::PENDING_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a validated petition" do
          before { petition.update_column(:state, Petition::VALIDATED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end

        describe "for a sponsored petition" do
          before { petition.update_column(:state, Petition::SPONSORED_STATE) }
          it_behaves_like "trying to email supporters of a petition in the wrong state"
        end
      end
    end

    describe "DELETE /admin/petitions/:petition_id/emails/:id" do
      let(:email) do
        FactoryBot.create(
          :petition_email,
          petition: petition,
          subject: "Petition email subject",
          body: "Petition email body"
        )
      end

      def do_delete(overrides = {})
        params = { petition_id: petition.id, id: email.id }
        delete :destroy, params: params.merge(overrides)
      end

      describe "for an open petition" do
        let(:moderated) { double(:moderated) }
        let(:emails) { double(:emails) }

        before do
          expect(Petition).to receive(:moderated).and_return(moderated)
          expect(moderated).to receive(:find).with("#{petition.id}").and_return(petition)
          expect(petition).to receive(:emails).and_return(emails)
          expect(emails).to receive(:find).with("#{email.id}").and_return(email)
        end

        it "fetches the requested petition" do
          do_delete
          expect(assigns(:petition)).to eq petition
        end

        it "fetches the requested email" do
          do_delete
          expect(assigns(:email)).to eq email
        end

        context "when the delete is successful" do
          before do
            expect(email).to receive(:destroy).and_return(true)
          end

          it "redirects to the petition emails page" do
            do_delete
            expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
          end

          it "tells the moderator that the record was deleted" do
            do_delete
            expect(flash[:notice]).to eq "Deleted other Senedd business successfully"
          end
        end

        context "when the delete is unsuccessful" do
          before do
            expect(email).to receive(:destroy).and_return(false)
          end

          it "redirects to the petition emails page" do
            do_delete
            expect(response).to redirect_to "https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}/emails"
          end

          it "tells the moderator to contact support" do
            do_delete
            expect(flash[:notice]).to eq "Unable to delete other Senedd business - please contact support"
          end
        end
      end
    end
  end
end
