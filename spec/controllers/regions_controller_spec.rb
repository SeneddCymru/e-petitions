require 'rails_helper'

RSpec.describe RegionsController, type: :controller do
  shared_examples "a Region API controller" do
    it "responds with 200 OK" do
      expect(response.status).to eq(200)
    end

    it "assigns the @regions instance variable" do
      expect(assigns[:regions]).not_to be_nil
    end

    it "renders the regions/index template" do
      expect(response).to render_template("regions/index")
    end

    it "sets the Access-Control-Allow-Origin header to '*'" do
      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end

    it "sets the Access-Control-Allow-Methods header to 'GET'" do
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET")
    end

    it "sets the Access-Control-Allow-Headers header to 'Origin, X-Requested-With, Content-Type, Accept'" do
      expect(response.headers["Access-Control-Allow-Headers"]).to eq("Origin, X-Requested-With, Content-Type, Accept")
    end
  end

  describe "GET /regions.json" do
    before do
      get :index, format: "json"
    end

    it_behaves_like "a Region API controller"
  end

  describe "GET /regions.geojson" do
    before do
      get :index, format: "geojson"
    end

    it_behaves_like "a Region API controller"
  end
end
