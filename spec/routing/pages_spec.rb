require 'rails_helper'

RSpec.describe "pages", type: :routes do
  describe "English", english: true do
    describe "routes" do
      it "GET / routes to pages#index" do
        expect(get("/")).to route_to(controller: "pages", action: "index")
      end

      it "GET /help routes to pages#help" do
        expect(get("/help")).to route_to(controller: "pages", action: "help")
      end

      it "GET /privacy routes to pages#privacy" do
        expect(get("/privacy")).to route_to(controller: "pages", action: "privacy")
      end
    end

    describe "redirects" do
      it "GET /cuideachadh" do
        expect(get("/cuideachadh")).to redirect_to("/help", 308)
      end

      it "GET /priobhaideachd" do
        expect(get("/priobhaideachd")).to redirect_to("/privacy", 308)
      end
    end

    describe "helpers" do
      it "#home_url generates https://petitions.parliament.scot/" do
        expect(home_url).to eq("https://petitions.parliament.scot/")
      end

      it "#help_url generates https://petitions.parliament.scot/help" do
        expect(help_url).to eq("https://petitions.parliament.scot/help")
      end

      it "#privacy_url generates https://petitions.parliament.scot/privacy" do
        expect(privacy_url).to eq("https://petitions.parliament.scot/privacy")
      end
    end
  end

  describe "Gaelic", gaelic: true do
    describe "routes" do
      it "GET / routes to pages#index" do
        expect({:get => "/"}).to route_to(controller: "pages", action: "index")
      end

      it "GET /cuideachadh routes to pages#help" do
        expect({:get => "/cuideachadh"}).to route_to(controller: "pages", action: "help")
      end

      it "GET /priobhaideachd routes to pages#privacy" do
        expect({:get => "/priobhaideachd"}).to route_to(controller: "pages", action: "privacy")
      end
    end

    describe "redirects" do
      it "GET /help" do
        expect(get("/help")).to redirect_to("/cuideachadh", 308)
      end

      it "GET /privacy" do
        expect(get("/privacy")).to redirect_to("/priobhaideachd", 308)
      end
    end

    describe "helpers" do
      it "#home_url generates https://athchuingean.parlamaid-alba.scot/" do
        expect(home_url).to eq("https://athchuingean.parlamaid-alba.scot/")
      end

      it "#help_url generates https://athchuingean.parlamaid-alba.scot/cuideachadh" do
        expect(help_url).to eq("https://athchuingean.parlamaid-alba.scot/cuideachadh")
      end

      it "#privacy_url generates https://athchuingean.parlamaid-alba.scot/priobhaideachd" do
        expect(privacy_url).to eq("https://athchuingean.parlamaid-alba.scot/priobhaideachd")
      end
    end
  end
end
