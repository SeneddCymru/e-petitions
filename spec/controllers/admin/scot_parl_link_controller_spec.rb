require 'rails_helper'

RSpec.describe Admin::ScotParlLinkController, type: :controller, admin: true do

  let!(:petition) { FactoryBot.create(:closed_petition) }

  describe "not logged in" do
    describe "GET /show" do
      it "redirects to the login page" do
        get :show, params: { petition_id: petition.to_param }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end

    describe "PATCH /update" do
      it "redirects to the login page" do
        patch :update, params: { petition_id: petition.to_param }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /show" do
      it "redirects to edit profile page" do
        get :show, params: { petition_id: petition.to_param }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end

    describe "PATCH /update" do
      it "redirects to edit profile page" do
        patch :update, params: { petition_id: petition.to_param }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /show" do
      it "fetches the requested petition" do
        get :show, params: { petition_id: petition.to_param }
        expect(assigns(:petition)).to eq petition
      end

      it "responds successfully and renders the petitions/show template" do
        get :show, params: { petition_id: petition.to_param }
        expect(response).to be_successful
        expect(response).to render_template("petitions/show")
      end
    end

    describe "PATCH /update" do
      let(:attributes) do
        {
          scot_parl_link_en: "https://www.parliament.scot/getting-involved/petitions/PE01319",
          scot_parl_link_gd: "https://www.parlamaid-alba.scot/a-dol-an-sas/athchuingean/PE01319"
        }
      end

      before do
        patch :update, params: { petition_id: petition.to_param, petition: attributes }
      end

      it "fetches the requested petition" do
        expect(assigns(:petition)).to eq petition
      end

      it "redirects to the petition show page" do
        expect(response).to redirect_to "https://moderate.petitions.parliament.scot/admin/petitions/#{petition.to_param}"
      end

      it "sets the flash notice message" do
        expect(flash[:notice]).to eq("Petition has been successfully updated")
      end

      it "stores the English link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.scot_parl_link_en
        }.from(nil).to(a_string_matching("www.parliament.scot"))
      end

      it "stores the Gaelic link in the database" do
        expect {
          petition.reload
        }.to change {
          petition.scot_parl_link_gd
        }.from(nil).to(a_string_matching("www.parlamaid-alba.scot"))
      end

      context "when the update fails" do
        before do
          expect(Petition).to receive(:find).with(petition.to_param).and_return(petition)
          expect(petition).to receive(:update).and_return(false)
        end

        it "renders the petition page" do
          patch :update, params: { petition_id: petition.to_param, petition: attributes }
          expect(response).to have_rendered("admin/petitions/show")
        end

        it "displays an alert" do
          patch :update, params: { petition_id: petition.to_param, petition: attributes }
          expect(flash[:alert]).to eq("Petition could not be updated - please check the form for errors")
        end
      end
    end
  end
end
