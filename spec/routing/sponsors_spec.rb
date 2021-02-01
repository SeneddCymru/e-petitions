require 'rails_helper'

RSpec.describe "routes for sponsor", type: :routes do
  describe "English", english: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /petitions/1/sponsors" do
      expect(get("/petitions/1/sponsors")).not_to be_routable
    end

    it "routes GET /petitions/1/sponsors/new to sponsors#new" do
      expect(get("/petitions/1/sponsors/new")).to route_to("sponsors#new", petition_id: "1")
    end

    it "routes POST /petitions/1/sponsors/new to sponsors#confirm" do
      expect(post("/petitions/1/sponsors/new")).to route_to("sponsors#confirm", petition_id: "1")
    end

    it "routes POST /petitions/1/sponsors to sponsors#create" do
      expect(post("/petitions/1/sponsors")).to route_to("sponsors#create", petition_id: "1")
    end

    it "routes GET /petitions/1/sponsors/thank-you to sponsors#thank_you" do
      expect(get("/petitions/1/sponsors/thank-you")).to route_to("sponsors#thank_you", petition_id: "1")
    end

    it "doesn't route GET /petitions/1/sponsors/2" do
      expect(get("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route GET /petitions/1/sponsors/2/edit" do
      expect(get("/petitions/1/sponsors/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/1/sponsors/2" do
      expect(patch("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route PUT /petitions/1/sponsors/2" do
      expect(put("/petitions/1/sponsors/2")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/1/sponsors/2" do
      expect(delete("/petitions/1/sponsors/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /sponsors/1/verify to sponsors#verify" do
      expect(get("/sponsors/1/verify?token=abcdef1234567890")).
        to route_to("sponsors#verify", id: "1", token: "abcdef1234567890")

      expect(verify_sponsor_path("1", token: "abcdef1234567890")).to eq("/sponsors/1/verify?token=abcdef1234567890")
    end

    it "doesn't route GET /sponsors/1/unsubscribe" do
      expect(delete("/sponsors/1/unsubscribe")).not_to be_routable
    end

    it "routes GET /sponsors/1/sponsored to sponsors#signed" do
      expect(get("/sponsors/1/sponsored?token=abcdef1234567890")).
        to route_to("sponsors#signed", id: "1", token: "abcdef1234567890")

      expect(signed_sponsor_path("1", token: "abcdef1234567890")).to eq("/sponsors/1/sponsored?token=abcdef1234567890")
    end

    it "doesn't route GET /sponsors" do
      expect(get("/sponsors")).not_to be_routable
    end

    it "doesn't route GET /sponsors/new" do
      expect(get("/sponsors/new")).not_to be_routable
    end

    it "doesn't route POST /sponsors" do
      expect(post("/sponsors")).not_to be_routable
    end

    it "doesn't route GET /sponsors/1" do
      expect(get("/sponsors/2")).not_to be_routable
    end

    it "doesn't route GET /sponsors/1/edit" do
      expect(get("/sponsors/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /sponsors/1" do
      expect(patch("/sponsors/2")).not_to be_routable
    end

    it "doesn't route DELETE /sponsors/1" do
      expect(delete("/sponsors/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /athchuingean/1/luchd-taic/ur" do
        expect(get("/athchuingean/1/luchd-taic/ur")).to redirect_to("/petitions/1/sponsors/new", 308)
      end

      it "POST /athchuingean/1/luchd-taic/ur" do
        expect(post("/athchuingean/1/luchd-taic/ur")).to redirect_to("/petitions/1/sponsors/new", 308)
      end

      it "POST /athchuingean/1/luchd-taic" do
        expect(post("/athchuingean/1/luchd-taic")).to redirect_to("/petitions/1/sponsors", 308)
      end

      it "GET /athchuingean/1/luchd-taic/tapadh-leibh" do
        expect(get("/athchuingean/1/luchd-taic/tapadh-leibh")).to redirect_to("/petitions/1/sponsors/thank-you", 308)
      end

      it "GET /luchd-taic/1/dearbhaich" do
        expect(get("/luchd-taic/1/dearbhaich?token=abcdef1234567890")).to redirect_to("/sponsors/1/verify?token=abcdef1234567890", 308)
      end

      it "GET /luchd-taic/1/urrasach" do
        expect(get("/luchd-taic/1/urrasach?token=abcdef1234567890")).to redirect_to("/sponsors/1/sponsored?token=abcdef1234567890", 308)
      end
    end
  end

  describe "Gaelic", gaelic: true do
    # Routes nested to /athchuingean/:petition_id
    it "doesn't route GET /athchuingean/1/luchd-taic" do
      expect(get("/athchuingean/1/luchd-taic")).not_to be_routable
    end

    it "routes GET /athchuingean/1/luchd-taic/ur to sponsors#new" do
      expect(get("/athchuingean/1/luchd-taic/ur")).to route_to("sponsors#new", petition_id: "1")
    end

    it "routes POST /athchuingean/1/luchd-taic/ur to sponsors#confirm" do
      expect(post("/athchuingean/1/luchd-taic/ur")).to route_to("sponsors#confirm", petition_id: "1")
    end

    it "routes POST /athchuingean/1/luchd-taic to sponsors#create" do
      expect(post("/athchuingean/1/luchd-taic")).to route_to("sponsors#create", petition_id: "1")
    end

    it "routes GET /athchuingean/1/luchd-taic/tapadh-leibh to sponsors#thank_you" do
      expect(get("/athchuingean/1/luchd-taic/tapadh-leibh")).to route_to("sponsors#thank_you", petition_id: "1")
    end

    it "doesn't route GET /athchuingean/1/luchd-taic/2" do
      expect(get("/athchuingean/1/luchd-taic/2")).not_to be_routable
    end

    it "doesn't route GET /athchuingean/1/luchd-taic/2/deasaich" do
      expect(get("/athchuingean/1/luchd-taic/2/deasaich")).not_to be_routable
    end

    it "doesn't route PATCH /athchuingean/1/luchd-taic/2" do
      expect(patch("/athchuingean/1/luchd-taic/2")).not_to be_routable
    end

    it "doesn't route PUT /athchuingean/1/luchd-taic/2" do
      expect(put("/athchuingean/1/luchd-taic/2")).not_to be_routable
    end

    it "doesn't route DELETE /athchuingean/1/luchd-taic/2" do
      expect(delete("/athchuingean/1/luchd-taic/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /luchd-taic/1/dearbhaich to sponsors#verify" do
      expect(get("/luchd-taic/1/dearbhaich?token=abcdef1234567890")).
        to route_to("sponsors#verify", id: "1", token: "abcdef1234567890")

      expect(verify_sponsor_path("1", token: "abcdef1234567890")).to eq("/luchd-taic/1/dearbhaich?token=abcdef1234567890")
    end

    it "doesn't route GET /luchd-taic/1/di-chlaradh" do
      expect(delete("/luchd-taic/1/di-chlaradh")).not_to be_routable
    end

    it "routes GET /luchd-taic/1/urrasach to sponsors#signed" do
      expect(get("/luchd-taic/1/urrasach?token=abcdef1234567890")).
        to route_to("sponsors#signed", id: "1", token: "abcdef1234567890")

      expect(signed_sponsor_path("1", token: "abcdef1234567890")).to eq("/luchd-taic/1/urrasach?token=abcdef1234567890")
    end

    it "doesn't route GET /luchd-taic" do
      expect(get("/luchd-taic")).not_to be_routable
    end

    it "doesn't route GET /luchd-taic/ur" do
      expect(get("/luchd-taic/ur")).not_to be_routable
    end

    it "doesn't route POST /luchd-taic" do
      expect(post("/luchd-taic")).not_to be_routable
    end

    it "doesn't route GET /luchd-taic/1" do
      expect(get("/luchd-taic/2")).not_to be_routable
    end

    it "doesn't route GET /luchd-taic/1/deasaich" do
      expect(get("/luchd-taic/2/deasaich")).not_to be_routable
    end

    it "doesn't route PATCH /luchd-taic/1" do
      expect(patch("/luchd-taic/2")).not_to be_routable
    end

    it "doesn't route DELETE /luchd-taic/1" do
      expect(delete("/luchd-taic/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /petitions/1/sponsors/new" do
        expect(get("/petitions/1/sponsors/new")).to redirect_to("/athchuingean/1/luchd-taic/ur", 308)
      end

      it "POST /petitions/1/sponsors/new" do
        expect(post("/petitions/1/sponsors/new")).to redirect_to("/athchuingean/1/luchd-taic/ur", 308)
      end

      it "POST /petitions/1/sponsors" do
        expect(post("/petitions/1/sponsors")).to redirect_to("/athchuingean/1/luchd-taic", 308)
      end

      it "GET /petitions/1/sponsors/thank-you" do
        expect(get("/petitions/1/sponsors/thank-you")).to redirect_to("/athchuingean/1/luchd-taic/tapadh-leibh", 308)
      end

      it "GET /sponsors/1/verify" do
        expect(get("/sponsors/1/verify?token=abcdef1234567890")).to redirect_to("/luchd-taic/1/dearbhaich?token=abcdef1234567890", 308)
      end

      it "GET /sponsors/1/sponsored" do
        expect(get("/sponsors/1/sponsored?token=abcdef1234567890")).to redirect_to("/luchd-taic/1/urrasach?token=abcdef1234567890", 308)
      end
    end
  end
end
