require 'rails_helper'

RSpec.describe "routes for local petitions", type: :routes do
  describe "English", english: true do
    it "routes GET /petitions/local to local_petitions#index" do
      expect(get("/petitions/local")).to route_to("local_petitions#index")
    end

    it "routes GET /petitions/local/glasgow to local_petitions#show" do
      expect(get("/petitions/local/glasgow")).to route_to("local_petitions#show", id: "glasgow")
    end

    it "routes GET /petitions/local/glasgow/all to local_petitions#show" do
      expect(get("/petitions/local/glasgow/all")).to route_to("local_petitions#all", id: "glasgow")
    end

    describe "redirects" do
      it "GET /deisebau/lleol" do
        expect(get("/deisebau/lleol")).to redirect_to("/petitions/local", 308)
      end

      it "GET /deisebau/lleol/glaschu" do
        expect(get("/deisebau/lleol/glaschu")).to redirect_to("/petitions/local/glaschu", 308)
      end

      it "GET /deisebau/lleol/glaschu/bob" do
        expect(get("/deisebau/lleol/glaschu/bob")).to redirect_to("/petitions/local/glaschu/all", 308)
      end
    end
  end

  describe "Gaelic", gaelic: true do
    it "routes GET /deisebau/lleol to local_petitions#index" do
      expect(get("/deisebau/lleol")).to route_to("local_petitions#index")
    end

    it "routes GET /deisebau/lleol/glaschu to local_petitions#show" do
      expect(get("/deisebau/lleol/glaschu")).to route_to("local_petitions#show", id: "glaschu")
    end

    it "routes GET /deisebau/lleol/glaschu/bob to local_petitions#all" do
      expect(get("/deisebau/lleol/glaschu/bob")).to route_to("local_petitions#all", id: "glaschu")
    end

    describe "redirects" do
      it "GET /petitions/local" do
        expect(get("/petitions/local")).to redirect_to("/deisebau/lleol", 308)
      end

      it "GET /petitions/local/glasgow" do
        expect(get("/petitions/local/glasgow")).to redirect_to("/deisebau/lleol/glasgow", 308)
      end

      it "GET /petitions/local/glasgow/all" do
        expect(get("/petitions/local/glasgow/all")).to redirect_to("/deisebau/lleol/glasgow/bob", 308)
      end
    end
  end
end
