require 'rails_helper'

RSpec.describe MapsController, type: :controller do
  describe "GET /petitions/:id/map" do
    let(:petition) { double(to_param: "1") }

    it "assigns the given petition" do
      expect(petition).to receive(:collecting_sponsors?).and_return(false)
      expect(petition).to receive(:in_moderation?).and_return(false)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :show, params: { petition_id: 1 }
      expect(assigns(:petition)).to eq(petition)
      expect(response).to render_template('layouts/maps')
      expect(response).to render_template('maps/show')
    end

    it "does not allow hidden petitions to be shown" do
      expect(Petition).to receive_message_chain(:show, :find).and_raise ActiveRecord::RecordNotFound

      expect {
        get :show, params: { petition_id: 1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not show petitions gathering sponsors" do
      expect(petition).to receive(:collecting_sponsors?).and_return(true)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :show, params: { petition_id: 1 }

      expect(response).to redirect_to "/petitions/1/gathering-support"
    end
  end

  describe "GET /petitions/:id/map/about" do
    let(:petition) { double(to_param: "1") }

    it "assigns the given petition" do
      expect(petition).to receive(:collecting_sponsors?).and_return(false)
      expect(petition).to receive(:in_moderation?).and_return(false)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :about, params: { petition_id: 1 }
      expect(assigns(:petition)).to eq(petition)
      expect(response).to render_template('layouts/application')
      expect(response).to render_template('maps/about')
    end

    it "does not allow hidden petitions to be shown" do
      expect(Petition).to receive_message_chain(:show, :find).and_raise ActiveRecord::RecordNotFound

      expect {
        get :about, params: { petition_id: 1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not show petitions gathering sponsors" do
      expect(petition).to receive(:collecting_sponsors?).and_return(true)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :about, params: { petition_id: 1 }

      expect(response).to redirect_to "/petitions/1/gathering-support"
    end
  end

  describe "GET /petitions/:id/map/share" do
    let(:petition) { double(to_param: "1") }

    it "assigns the given petition" do
      expect(petition).to receive(:collecting_sponsors?).and_return(false)
      expect(petition).to receive(:in_moderation?).and_return(false)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :share, params: { petition_id: 1 }
      expect(assigns(:petition)).to eq(petition)
      expect(response).to render_template('layouts/application')
      expect(response).to render_template('maps/share')
    end

    it "does not allow hidden petitions to be shown" do
      expect(Petition).to receive_message_chain(:show, :find).and_raise ActiveRecord::RecordNotFound

      expect {
        get :share, params: { petition_id: 1 }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not show petitions gathering sponsors" do
      expect(petition).to receive(:collecting_sponsors?).and_return(true)
      expect(Petition).to receive_message_chain(:show, find: petition)

      get :share, params: { petition_id: 1 }

      expect(response).to redirect_to "/petitions/1/gathering-support"
    end
  end
end
