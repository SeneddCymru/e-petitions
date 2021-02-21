require 'rails_helper'

RSpec.describe Admin::ContentController, type: :controller, admin: true do
  let(:petition) do
    FactoryBot.create(:validated_petition)
  end

  describe "not logged in" do
    describe "POST /admin/petitions/:petition_id/content" do
      it "redirects to the login page" do
        post :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/login")
      end
    end
  end

  context "logged in as moderator user but need to reset password" do
    let(:user) { FactoryBot.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "POST /admin/petitions/:petition_id/content" do
      it "redirects to edit profile page" do
        patch :create, params: { petition_id: petition.id }
        expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin/profile/#{user.id}/edit")
      end
    end
  end

  describe "logged in as moderator user" do
    let(:user) { FactoryBot.create(:moderator_user) }
    before { login_as(user) }

    describe "POST /admin/petitions/:petition_id/content" do
      context "when the petition doesn't exist" do
        before { post :create, params: { petition_id: "999999" } }

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Sorry, we couldn't find petition 999999")
        end
      end

      context "when the petition exists" do
        before do
          allow(petition).to receive(:copy_content!).and_return true
          allow(Petition).to receive(:find).and_return petition

          post :create, params: { petition_id: petition.id }
        end

        it "calls .copy_content! on the petition" do
          expect(petition).to have_received(:copy_content!)
        end

        it "redirects to the petition page" do
          expect(flash[:notice]).to eq("The petition's content has been copied over to the Gaelic version")
        end
      end
    end

    describe "DELETE /admin/petitions/:petition_id/content" do
      context "when the petition doesn't exist" do
        before { delete :destroy, params: { petition_id: "999999" } }

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petitions.parliament.scot/admin")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Sorry, we couldn't find petition 999999")
        end
      end

      context "when the petition exists" do
        before do
          allow(petition).to receive(:reset_content!).and_return true
          allow(Petition).to receive(:find).and_return petition

          delete :destroy, params: { petition_id: petition.id }
        end

        it "calls .reset_content! on the petition" do
          expect(petition).to have_received(:reset_content!)
        end

        it "redirects to the petition page" do
          expect(flash[:notice]).to eq("The Gaelic version of the petition's content has been reset")
        end
      end
    end
  end
end
