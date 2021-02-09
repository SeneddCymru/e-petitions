require 'rails_helper'

RSpec.describe "routes for petitions", type: :routes do
  describe "English", english: true do
    it "routes GET /petitions to petitions#index" do
      expect(get("/petitions")).to route_to(controller: "petitions", action: "index")
      expect(petitions_path).to eq("/petitions")
    end

    it "routes GET /petitions/new to petitions#new" do
      expect(get("/petitions/new")).to route_to(controller: "petitions", action: "new")
      expect(new_petition_path).to eq("/petitions/new")
    end

    it "routes POST /petitions/new to petitions#create" do
      expect(post("/petitions/new")).to route_to(controller: "petitions", action: "create")
      expect(new_petition_path).to eq("/petitions/new")
    end

    it "routes GET /petitions/thank-you to petitions#thank_you" do
      expect(get("/petitions/thank-you")).to route_to(controller: "petitions", action: "thank_you")
      expect(thank_you_petitions_path).to eq("/petitions/thank-you")
    end

    it "doesn't route POST /petitions" do
      expect(post("/petitions")).not_to be_routable
    end

    it "doesn't route GET /petitions/:id/edit" do
      expect(patch("/petitions/1/edit")).not_to be_routable
    end

    it "doesn't route PATCH /petitions/:id" do
      expect(patch("/petitions/1")).not_to be_routable
    end

    it "doesn't route PUT /petitions/:id" do
      expect(put("/petitions/1")).not_to be_routable
    end

    it "doesn't route DELETE /petitions/:id" do
      expect(delete("/petitions/1")).not_to be_routable
    end

    it "routes GET /petitions/check to petitions#check" do
      expect(get("/petitions/check")).to route_to(controller: "petitions", action: "check")
      expect(check_petitions_path).to eq("/petitions/check")
    end

    it "routes GET /petitions/check-results to petitions#check_results" do
      expect(get("/petitions/check-results")).to route_to(controller: "petitions", action: "check_results")
      expect(check_results_petitions_path).to eq("/petitions/check-results")
    end

    it "routes GET /petitions/:id/count to petitions#count" do
      expect(get("/petitions/PE0001/count")).to route_to(controller: "petitions", action: "count", id: "PE0001")
      expect(count_petition_path("PE0001")).to eq("/petitions/PE0001/count")
    end

    it "routes GET /petitions/:id/gathering-support to petitions#gathering_support" do
      expect(get("/petitions/PE0001/gathering-support")).to route_to(controller: "petitions", action: "gathering_support", id: "PE0001")
      expect(gathering_support_petition_path("PE0001")).to eq("/petitions/PE0001/gathering-support")
    end

    it "routes GET /petitions/:id/moderation-info to petitions#moderation_info" do
      expect(get("/petitions/PE0001/moderation-info")).to route_to(controller: "petitions", action: "moderation_info", id: "PE0001")
      expect(moderation_info_petition_path("PE0001")).to eq("/petitions/PE0001/moderation-info")
    end

    context "when petitions do not need to collect sponsors to be submitted for moderation" do
      before do
        Site.instance.update!(
          minimum_number_of_sponsors: 0,
          threshold_for_moderation: 0
        )
      end

      it "routes GET /petitions/PE:id/count to petitions#count" do
        expect(get("/petitions/PE0001/count")).to route_to(controller: "petitions", action: "count", id: "PE0001")
        expect(count_petition_path("PE0001")).to eq("/petitions/PE0001/count")
      end
    end

    describe "redirects" do
      it "GET /athchuingean" do
        expect(get("/athchuingean")).to redirect_to("/petitions", 308)
      end

      it "GET /athchuingean/ur" do
        expect(get("/athchuingean/ur")).to redirect_to("/petitions/new", 308)
      end

      it "POST /athchuingean/ur" do
        expect(post("/athchuingean/ur")).to redirect_to("/petitions/new", 308)
      end

      it "GET /athchuingean/:id" do
        expect(get("/athchuingean/PE0001")).to redirect_to("/petitions/PE0001", 308)
      end

      it "GET /athchuingean/thoir-suil" do
        expect(get("/athchuingean/thoir-suil")).to redirect_to("/petitions/check", 308)
      end

      it "GET /athchuingean/thoir-suil-air-toraidhean" do
        expect(get("/athchuingean/thoir-suil-air-toraidhean")).to redirect_to("/petitions/check-results", 308)
      end

      it "GET /athchuingean/:id/cunnt" do
        expect(get("/athchuingean/PE0001/cunnt")).to redirect_to("/petitions/PE0001/count", 308)
      end

      it "GET /athchuingean/tapadh-leibh" do
        expect(get("/athchuingean/tapadh-leibh")).to redirect_to("/petitions/thank-you", 308)
      end

      it "GET /athchuingean/:id/cruinneachadh-taic" do
        expect(get("/athchuingean/PE0001/cruinneachadh-taic")).to redirect_to("/petitions/PE0001/gathering-support", 308)
      end

      it "GET /athchuingean/:id/fiosrachadh-measaidh" do
        expect(get("/athchuingean/PE0001/fiosrachadh-measaidh")).to redirect_to("/petitions/PE0001/moderation-info", 308)
      end
    end
  end

  describe "Gaelic", gaelic: true do
    it "routes GET /athchuingean to petitions#index" do
      expect(get("/athchuingean")).to route_to(controller: "petitions", action: "index")
      expect(petitions_path).to eq("/athchuingean")
    end

    it "routes GET /athchuingean/ur to petitions#new" do
      expect(get("/athchuingean/ur")).to route_to(controller: "petitions", action: "new")
      expect(new_petition_path).to eq("/athchuingean/ur")
    end

    it "routes POST /athchuingean/ur to petitions#create" do
      expect(post("/athchuingean/ur")).to route_to(controller: "petitions", action: "create")
      expect(new_petition_path).to eq("/athchuingean/ur")
    end

    it "routes GET /athchuingean/tapadh-leibh to petitions#thank_you" do
      expect(get("/athchuingean/tapadh-leibh")).to route_to(controller: "petitions", action: "thank_you")
      expect(thank_you_petitions_path).to eq("/athchuingean/tapadh-leibh")
    end

    it "doesn't route POST /petitions" do
      expect(post("/athchuingean")).not_to be_routable
    end

    it "routes GET /athchuingean/:id to petitions#show" do
      expect(get("/athchuingean/PE0001")).to route_to(controller: "petitions", action: "show", id: "PE0001")
      expect(petition_path("PE0001")).to eq("/athchuingean/PE0001")
    end

    it "doesn't route GET /athchuingean/:id/deasaich" do
      expect(patch("/athchuingean/1/deasaich")).not_to be_routable
    end

    it "doesn't route PATCH /athchuingean/:id" do
      expect(patch("/athchuingean/1")).not_to be_routable
    end

    it "doesn't route PUT /athchuingean/:id" do
      expect(put("/athchuingean/1")).not_to be_routable
    end

    it "doesn't route DELETE /athchuingean/:id" do
      expect(delete("/athchuingean/1")).not_to be_routable
    end

    it "routes GET /athchuingean/thoir-suil to petitions#check" do
      expect(get("/athchuingean/thoir-suil")).to route_to(controller: "petitions", action: "check")
      expect(check_petitions_path).to eq("/athchuingean/thoir-suil")
    end

    it "routes GET /athchuingean/thoir-suil-air-toraidhean to petitions#check_results" do
      expect(get("/athchuingean/thoir-suil-air-toraidhean")).to route_to(controller: "petitions", action: "check_results")
      expect(check_results_petitions_path).to eq("/athchuingean/thoir-suil-air-toraidhean")
    end

    it "routes GET /athchuingean/:id/cunnt to petitions#count" do
      expect(get("/athchuingean/PE0001/cunnt")).to route_to(controller: "petitions", action: "count", id: "PE0001")
      expect(count_petition_path("PE0001")).to eq("/athchuingean/PE0001/cunnt")
    end

    it "routes GET /athchuingean/:id/cruinneachadh-taic to petitions#gathering_support" do
      expect(get("/athchuingean/PE0001/cruinneachadh-taic")).to route_to(controller: "petitions", action: "gathering_support", id: "PE0001")
      expect(gathering_support_petition_path("PE0001")).to eq("/athchuingean/PE0001/cruinneachadh-taic")
    end

    it "routes GET /athchuingean/:id/fiosrachadh-measaidh to petitions#moderation_info" do
      expect(get("/athchuingean/PE0001/fiosrachadh-measaidh")).to route_to(controller: "petitions", action: "moderation_info", id: "PE0001")
      expect(moderation_info_petition_path("PE0001")).to eq("/athchuingean/PE0001/fiosrachadh-measaidh")
    end

    describe "redirects" do
      it "GET /petitions" do
        expect(get("/petitions")).to redirect_to("/athchuingean", 308)
      end

      it "GET /petitions/new" do
        expect(get("/petitions/new")).to redirect_to("/athchuingean/ur", 308)
      end

      it "POST /petitions/new" do
        expect(post("/petitions/new")).to redirect_to("/athchuingean/ur", 308)
      end

      it "GET /petitions/:id" do
        expect(get("/petitions/PE0001")).to redirect_to("/athchuingean/PE0001", 308)
      end

      it "GET /petitions/check" do
        expect(get("/petitions/check")).to redirect_to("/athchuingean/thoir-suil", 308)
      end

      it "GET /petitions/check-results" do
        expect(get("/petitions/check-results")).to redirect_to("/athchuingean/thoir-suil-air-toraidhean", 308)
      end

      it "GET /petitions/:id/count" do
        expect(get("/petitions/PE0001/count")).to redirect_to("/athchuingean/PE0001/cunnt", 308)
      end

      it "GET /petitions/thank-you" do
        expect(get("/petitions/thank-you")).to redirect_to("/athchuingean/tapadh-leibh", 308)
      end

      it "GET /petitions/:id/gathering-support" do
        expect(get("/petitions/PE0001/gathering-support")).to redirect_to("/athchuingean/PE0001/cruinneachadh-taic", 308)
      end

      it "GET /petitions/:id/moderation-info" do
        expect(get("/petitions/PE0001/moderation-info")).to redirect_to("/athchuingean/PE0001/fiosrachadh-measaidh", 308)
      end
    end
  end
end
