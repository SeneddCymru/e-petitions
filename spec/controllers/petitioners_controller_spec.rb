require 'rails_helper'

RSpec.describe PetitionersController, type: :controller do
  before do
    constituency = FactoryBot.create(:constituency, :glasgow_provan)
    allow(Constituency).to receive(:find_by_postcode).with("G340BX").and_return(constituency)

    Site.instance.update!(
      minimum_number_of_sponsors: 0,
      threshold_for_moderation: 0
    )
  end

  describe "GET /petitioners/:id/verify" do
    context "when the signature doesn't exist" do
      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: 1, token: "token" }
        }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end

    context "when the signature token is invalid" do
      let(:petition) { FactoryBot.create(:open_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      it "raises an ActiveRecord::RecordNotFound exception" do
        expect {
          get :verify, params: { id: signature.id, token: "token" }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the petition is pending" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }
      let(:creator) { petition.creator }

      before do
        get :verify, params: { id: signature.id, token: signature.perishable_token }
      end

      it "validates the creator's signature" do
        expect(creator.reload.validated?).to eq(true)
      end

      it "changes the petition state to sponsored" do
        expect(petition.reload.state).to eq("sponsored")
      end

      it "redirects to the thank you page" do
        expect(response).to redirect_to("/petitioners/#{signature.id}/thank-you")
      end
    end

    %w[validated sponsored].each do |state|
      context "when the petition is #{state}" do
        let(:petition) { FactoryBot.create(:"#{state}_petition") }
        let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

        before do
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        end

        it "redirects to the thank you page" do
          expect(response).to redirect_to("/petitioners/#{signature.id}/thank-you")
        end
      end
    end

    context "when the site is collecting sponsors" do
      let(:petition) { FactoryBot.create(:pending_petition) }
      let(:signature) { FactoryBot.create(:pending_signature, petition: petition) }

      before do
        Site.instance.update!(
          minimum_number_of_sponsors: 2,
          threshold_for_moderation: 2
        )
      end

      it "returns a 404 error" do
        expect {
          get :verify, params: { id: signature.id, token: signature.perishable_token }
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end
end
