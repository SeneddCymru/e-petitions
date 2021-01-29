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
      it "GET /athchuingean/ionadail" do
        expect(get("/athchuingean/ionadail")).to redirect_to("/petitions/local", 308)
      end

      it "GET /athchuingean/ionadail/glaschu" do
        expect(get("/athchuingean/ionadail/glaschu")).to redirect_to("/petitions/local/glaschu", 308)
      end

      it "GET /athchuingean/ionadail/glaschu/uile" do
        expect(get("/athchuingean/ionadail/glaschu/uile")).to redirect_to("/petitions/local/glaschu/all", 308)
      end
    end
  end

  describe "Gaelic", gaelic: true do
    it "routes GET /athchuingean/ionadail to local_petitions#index" do
      expect(get("/athchuingean/ionadail")).to route_to("local_petitions#index")
    end

    it "routes GET /athchuingean/ionadail/glaschu to local_petitions#show" do
      expect(get("/athchuingean/ionadail/glaschu")).to route_to("local_petitions#show", id: "glaschu")
    end

    it "routes GET /athchuingean/ionadail/glaschu/uile to local_petitions#all" do
      expect(get("/athchuingean/ionadail/glaschu/uile")).to route_to("local_petitions#all", id: "glaschu")
    end

    describe "redirects" do
      it "GET /petitions/local" do
        expect(get("/petitions/local")).to redirect_to("/athchuingean/ionadail", 308)
      end

      it "GET /petitions/local/glasgow" do
        expect(get("/petitions/local/glasgow")).to redirect_to("/athchuingean/ionadail/glasgow", 308)
      end

      it "GET /petitions/local/glasgow/all" do
        expect(get("/petitions/local/glasgow/all")).to redirect_to("/athchuingean/ionadail/glasgow/uile", 308)
      end
    end
  end
end
