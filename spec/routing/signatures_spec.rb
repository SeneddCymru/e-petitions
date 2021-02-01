require 'rails_helper'

RSpec.describe "routes for signatures", type: :routes do
  describe "English", english: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /petitions/1/signatures" do
      expect(get("/petitions/1/signatures")).not_to be_routable
    end

    it "routes GET /petitions/1/signatures/new to signatures#new" do
      expect(get("/petitions/1/signatures/new")).to route_to("signatures#new", petition_id: "1")
    end

    it "routes POST /petitions/1/signatures/new to signatures#confirm" do
      expect(post("/petitions/1/signatures/new")).to route_to("signatures#confirm", petition_id: "1")
    end

    it "routes POST /petitions/1/signatures to signatures#create" do
      expect(post("/petitions/1/signatures")).to route_to("signatures#create", petition_id: "1")
    end

    it "routes GET /petitions/1/signatures/thank-you to signatures#thank_you" do
      expect(get("/petitions/1/signatures/thank-you")).to route_to("signatures#thank_you", petition_id: "1")
    end

    it "doesn't route GET /petitions/1/signatures/2" do
      expect(get("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route GET /petitions/1/signatures/2/edit" do
      expect(get("/petitions/1/signatures/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/1/signatures/2" do
      expect(patch("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route PUT /petitions/1/signatures/2" do
      expect(put("/petitions/1/signatures/2")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/1/signatures/2" do
      expect(delete("/petitions/1/signatures/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /signatures/1/verify to signatures#verify" do
      expect(get("/signatures/1/verify?token=abcdef1234567890")).
        to route_to("signatures#verify", id: "1", token: "abcdef1234567890")

      expect(verify_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/verify?token=abcdef1234567890")
    end

    it "routes GET /signatures/1/unsubscribe to signatures#unsubscribe" do
      expect(get("/signatures/1/unsubscribe?token=abcdef1234567890")).
        to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")

      expect(unsubscribe_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/unsubscribe?token=abcdef1234567890")
    end

    it "routes GET /signatures/1/signed to signatures#signed" do
      expect(get("/signatures/1/signed?token=abcdef1234567890")).
        to route_to("signatures#signed", id: "1", token: "abcdef1234567890")

      expect(signed_signature_path("1", token: "abcdef1234567890")).to eq("/signatures/1/signed?token=abcdef1234567890")
    end

    it "doesn't route GET /signatures" do
      expect(get("/signatures")).not_to be_routable
    end

    it "doesn't route GET /signatures/new" do
      expect(get("/signatures/new")).not_to be_routable
    end

    it "doesn't route POST /signatures" do
      expect(post("/signatures")).not_to be_routable
    end

    it "doesn't route GET /signatures/1" do
      expect(get("/signatures/2")).not_to be_routable
    end

    it "doesn't route GET /signatures/1/edit" do
      expect(get("/signatures/2/edit")).not_to be_routable
    end

    it "doesn't route PATCH /signatures/1" do
      expect(patch("/signatures/2")).not_to be_routable
    end

    it "doesn't route DELETE /signatures/1" do
      expect(delete("/signatures/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /athchuingean/1/ainmean-sgriobhte/ur" do
        expect(get("/athchuingean/1/ainmean-sgriobhte/ur")).to redirect_to("/petitions/1/signatures/new", 308)
      end

      it "POST /athchuingean/1/luchd-taic/ur" do
        expect(post("/athchuingean/1/ainmean-sgriobhte/ur")).to redirect_to("/petitions/1/signatures/new", 308)
      end

      it "POST /athchuingean/1/ainmean-sgriobhte" do
        expect(post("/athchuingean/1/ainmean-sgriobhte")).to redirect_to("/petitions/1/signatures", 308)
      end

      it "GET /athchuingean/1/ainmean-sgriobhte/tapadh-leibh" do
        expect(get("/athchuingean/1/ainmean-sgriobhte/tapadh-leibh")).to redirect_to("/petitions/1/signatures/thank-you", 308)
      end

      it "GET /ainmean-sgriobhte/1/dearbhaich" do
        expect(get("/ainmean-sgriobhte/1/dearbhaich?token=abcdef1234567890")).to redirect_to("/signatures/1/verify?token=abcdef1234567890", 308)
      end

      it "GET /ainmean-sgriobhte/1/di-chlaradh" do
        expect(get("/ainmean-sgriobhte/1/di-chlaradh?token=abcdef1234567890")).to redirect_to("/signatures/1/unsubscribe?token=abcdef1234567890", 308)
      end

      it "GET /ainmean-sgriobhte/1/air-a-shoidhnigeadh" do
        expect(get("/ainmean-sgriobhte/1/air-a-shoidhnigeadh?token=abcdef1234567890")).to redirect_to("/signatures/1/signed?token=abcdef1234567890", 308)
      end
    end
  end

  describe "Gaelic", gaelic: true do
    # Routes nested to /petition/:petition_id
    it "doesn't route GET /athchuingean/1/ainmean-sgriobhte" do
      expect(get("/athchuingean/1/ainmean-sgriobhte")).not_to be_routable
    end

    it "routes GET /athchuingean/1/ainmean-sgriobhte/ur to signatures#new" do
      expect(get("/athchuingean/1/ainmean-sgriobhte/ur")).to route_to("signatures#new", petition_id: "1")
    end

    it "routes POST /athchuingean/1/ainmean-sgriobhte/ur to signatures#confirm" do
      expect(post("/athchuingean/1/ainmean-sgriobhte/ur")).to route_to("signatures#confirm", petition_id: "1")
    end

    it "routes POST /athchuingean/1/ainmean-sgriobhte to signatures#create" do
      expect(post("/athchuingean/1/ainmean-sgriobhte")).to route_to("signatures#create", petition_id: "1")
    end

    it "routes GET /athchuingean/1/ainmean-sgriobhte/tapadh-leibh to signatures#thank_you" do
      expect(get("/athchuingean/1/ainmean-sgriobhte/tapadh-leibh")).to route_to("signatures#thank_you", petition_id: "1")
    end

    it "doesn't route GET /athchuingean/1/ainmean-sgriobhte/2" do
      expect(get("/athchuingean/1/ainmean-sgriobhte/2")).not_to be_routable
    end

    it "doesn't route GET /athchuingean/1/ainmean-sgriobhte/2/deasaich" do
      expect(get("/athchuingean/1/ainmean-sgriobhte/2/deasaich")).not_to be_routable
    end

    it "doesn't route PATCH /athchuingean/1/ainmean-sgriobhte/2" do
      expect(patch("/athchuingean/1/ainmean-sgriobhte/2")).not_to be_routable
    end

    it "doesn't route PUT /athchuingean/1/ainmean-sgriobhte/2" do
      expect(put("/athchuingean/1/ainmean-sgriobhte/2")).not_to be_routable
    end

    it "doesn't route DELETE /athchuingean/1/ainmean-sgriobhte/2" do
      expect(delete("/athchuingean/1/ainmean-sgriobhte/2")).not_to be_routable
    end

    # un-nested routes
    it "routes GET /ainmean-sgriobhte/1/dearbhaich to signatures#verify" do
      expect(get("/ainmean-sgriobhte/1/dearbhaich?token=abcdef1234567890")).
        to route_to("signatures#verify", id: "1", token: "abcdef1234567890")

      expect(verify_signature_path("1", token: "abcdef1234567890")).to eq("/ainmean-sgriobhte/1/dearbhaich?token=abcdef1234567890")
    end

    it "routes GET /ainmean-sgriobhte/1/di-chlaradh to signatures#unsubscribe" do
      expect(get("/ainmean-sgriobhte/1/di-chlaradh?token=abcdef1234567890")).
        to route_to("signatures#unsubscribe", id: "1", token: "abcdef1234567890")

      expect(unsubscribe_signature_path("1", token: "abcdef1234567890")).to eq("/ainmean-sgriobhte/1/di-chlaradh?token=abcdef1234567890")
    end

    it "routes GET /ainmean-sgriobhte/1/air-a-shoidhnigeadh to signatures#signed" do
      expect(get("/ainmean-sgriobhte/1/air-a-shoidhnigeadh?token=abcdef1234567890")).
        to route_to("signatures#signed", id: "1", token: "abcdef1234567890")

      expect(signed_signature_path("1", token: "abcdef1234567890")).to eq("/ainmean-sgriobhte/1/air-a-shoidhnigeadh?token=abcdef1234567890")
    end

    it "doesn't route GET /ainmean-sgriobhte" do
      expect(get("/ainmean-sgriobhte")).not_to be_routable
    end

    it "doesn't route GET /ainmean-sgriobhte/ur" do
      expect(get("/ainmean-sgriobhte/ur")).not_to be_routable
    end

    it "doesn't route POST /ainmean-sgriobhte" do
      expect(post("/ainmean-sgriobhte")).not_to be_routable
    end

    it "doesn't route GET /ainmean-sgriobhte/1" do
      expect(post("/ainmean-sgriobhte/2")).not_to be_routable
    end

    it "doesn't route GET /ainmean-sgriobhte/1/deasaich" do
      expect(post("/ainmean-sgriobhte/2/deasaich")).not_to be_routable
    end

    it "doesn't route PATCH /ainmean-sgriobhte/1" do
      expect(patch("/ainmean-sgriobhte/2")).not_to be_routable
    end

    it "doesn't route DELETE /ainmean-sgriobhte/1" do
      expect(delete("/ainmean-sgriobhte/2")).not_to be_routable
    end

    describe "redirects" do
      it "GET /petitions/1/signatures/new" do
        expect(get("/petitions/1/signatures/new")).to redirect_to("/athchuingean/1/ainmean-sgriobhte/ur", 308)
      end

      it "POST /petitions/1/signatures/new" do
        expect(post("/petitions/1/signatures/new")).to redirect_to("/athchuingean/1/ainmean-sgriobhte/ur", 308)
      end

      it "POST /petitions/1/signatures" do
        expect(post("/petitions/1/signatures")).to redirect_to("/athchuingean/1/ainmean-sgriobhte", 308)
      end

      it "GET /petitions/1/signatures/thank-you" do
        expect(get("/petitions/1/signatures/thank-you")).to redirect_to("/athchuingean/1/ainmean-sgriobhte/tapadh-leibh", 308)
      end

      it "GET /signatures/1/verify" do
        expect(get("/signatures/1/verify?token=abcdef1234567890")).to redirect_to("/ainmean-sgriobhte/1/dearbhaich?token=abcdef1234567890", 308)
      end

      it "GET /signatures/1/unsubscribe" do
        expect(get("/signatures/1/unsubscribe?token=abcdef1234567890")).to redirect_to("/ainmean-sgriobhte/1/di-chlaradh?token=abcdef1234567890", 308)
      end

      it "GET /signatures/1/signed" do
        expect(get("/signatures/1/signed?token=abcdef1234567890")).to redirect_to("/ainmean-sgriobhte/1/air-a-shoidhnigeadh?token=abcdef1234567890", 308)
      end
    end
  end
end
