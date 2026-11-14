require 'rails_helper'

RSpec.describe Admin::PaperSignaturesController, type: :controller, admin: true do
  let!(:petition) { FactoryBot.create(:open_petition) }

  context "when not logged in" do
    describe "GET /admin/petitions/:petition_id/paper-signatures/new" do
      it "redirects to the login page" do
        get :new, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end

    describe "POST /admin/petitions/:petition_id/paper-signatures" do
      it "redirects to the login page" do
        post :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/login")
      end
    end
  end

  context "when logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/paper-signatures/new" do
      it "redirects to the edit profile page" do
        get :new, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end

    describe "POST /admin/petitions/:petition_id/paper-signatures" do
      it "redirects to the edit profile page" do
        post :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "when logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/petitions/:petition_id/paper-signatures/new" do
      render_views

      before { get :new, params: { petition_id: petition.id } }

      it "returns 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the :new template" do
        expect(response).to render_template("admin/paper_signatures/new")
      end

      it "defaults the location to Wales" do
        expect(response.body).to have_select("Location", selected: "Wales", options: ["Wales", "England", "Scotland", "Northern Ireland"])
      end

      it "renders the number of signatures field" do
        expect(response.body).to have_field("Number of signatures")
      end
    end

    describe "POST /admin/petitions/:petition_id/paper-signatures" do
      context "and the params are invalid" do
        before do
          post :create, params: { petition_id: petition.id, paper_signatures: { location_code: "GB-WLS", signature_count: "" } }
        end

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :new template" do
          expect(response).to render_template("admin/paper_signatures/new")
        end

        it "doesn't enqueue a job" do
          expect(enqueued_jobs).to be_empty
        end
      end

      context "and the params are valid" do
        before do
          post :create, params: { petition_id: petition.id, paper_signatures: { location_code: "GB-ENG", signature_count: "250" } }
        end

        it "enqueues a job to add the signatures" do
          expect(AddPaperSignaturesJob).to have_been_enqueued.with(petition, "GB-ENG", 250, "0.0.0.0")
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "sets the flash notice message" do
          expect(flash[:notice]).to eq("Paper signatures are being added to the petition - this may take a few minutes")
        end
      end

      context "and the job fails to enqueue" do
        before do
          allow(AddPaperSignaturesJob).to receive(:perform_later).and_return(false)
          post :create, params: { petition_id: petition.id, paper_signatures: { location_code: "GB-WLS", signature_count: "10" } }
        end

        it "redirects to the petition page" do
          expect(response).to redirect_to("https://moderate.petitions.senedd.wales/admin/petitions/#{petition.id}")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Paper signatures could not be added - please contact support")
        end
      end
    end
  end
end
