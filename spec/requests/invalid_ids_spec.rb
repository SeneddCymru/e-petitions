require 'rails_helper'

RSpec.describe "invalid ids", type: :request, show_exceptions: true, csrf: false do
  context "when on the English website" do
    describe "GET /petitions/:id" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:id/count.json" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/count.json"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:id/gathering-support" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/gathering-support"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:id/moderation-info" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/moderation-info"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:petition_id/sponsors/new" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/sponsors/new"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /petitions/:petition_id/sponsors/new" do
      it "returns a 404 Not Found" do
        post "/petitions/not-a-number/sponsors/new"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /petitions/:petition_id/sponsors" do
      it "returns a 404 Not Found" do
        post "/petitions/not-a-number/sponsors"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:petition_id/sponsors/thank-you" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/sponsors/thank-you"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /sponsors/:id/verify" do
      it "returns a 400 Bad Request" do
        get "/sponsors/not-a-number/verify"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /sponsors/:id/sponsored" do
      it "returns a 400 Bad Request" do
        get "/sponsors/not-a-number/sponsored"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /petitions/:petition_id/signatures/new" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/signatures/new"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /petitions/:petition_id/signatures/new" do
      it "returns a 404 Not Found" do
        post "/petitions/not-a-number/signatures/new"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /petitions/:petition_id/signatures" do
      it "returns a 404 Not Found" do
        post "/petitions/not-a-number/signatures"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /petitions/:petition_id/signatures/thank-you" do
      it "returns a 404 Not Found" do
        get "/petitions/not-a-number/signatures/thank-you"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /signatures/:id/verify" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/verify"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /signatures/:id/signed" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/signed"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /signatures/:id/unsubscribe" do
      it "returns a 400 Bad Request" do
        get "/signatures/not-a-number/unsubscribe"
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  context "when on the Gaelic website", gaelic: true do
    describe "GET /athchuingean/:id" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:id/cunnt.json" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/cunnt.json"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:id/cruinneachadh-taic" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/cruinneachadh-taic"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:id/fiosrachadh-measaidh" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/fiosrachadh-measaidh"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:petition_id/luchd-taic/ur" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/luchd-taic/ur"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /athchuingean/:petition_id/luchd-taic/ur" do
      it "returns a 404 Not Found" do
        post "/athchuingean/no-aireamh/luchd-taic/ur"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /athchuingean/:petition_id/luchd-taic" do
      it "returns a 404 Not Found" do
        post "/athchuingean/no-aireamh/luchd-taic"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:petition_id/luchd-taic/tapadh-leibh" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/luchd-taic/tapadh-leibh"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /luchd-taic/:id/dearbhaich" do
      it "returns a 400 Bad Request" do
        get "/luchd-taic/no-aireamh/dearbhaich"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /luchd-taic/:id/urrasach" do
      it "returns a 400 Bad Request" do
        get "/luchd-taic/no-aireamh/urrasach"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /athchuingean/:petition_id/ainmean-sgriobhte/ur" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/ainmean-sgriobhte/ur"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /athchuingean/:petition_id/ainmean-sgriobhte/ur" do
      it "returns a 404 Not Found" do
        post "/athchuingean/no-aireamh/ainmean-sgriobhte/ur"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /athchuingean/:petition_id/ainmean-sgriobhte" do
      it "returns a 404 Not Found" do
        post "/athchuingean/no-aireamh/ainmean-sgriobhte"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /athchuingean/:petition_id/ainmean-sgriobhte/tapadh-leibh" do
      it "returns a 404 Not Found" do
        get "/athchuingean/no-aireamh/ainmean-sgriobhte/tapadh-leibh"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /ainmean-sgriobhte/:id/dearbhaich" do
      it "returns a 400 Bad Request" do
        get "/ainmean-sgriobhte/no-aireamh/dearbhaich"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /ainmean-sgriobhte/:id/air-a-shoidhnigeadh" do
      it "returns a 400 Bad Request" do
        get "/ainmean-sgriobhte/no-aireamh/air-a-shoidhnigeadh"
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /ainmean-sgriobhte/:id/di-chlaradh" do
      it "returns a 400 Bad Request" do
        get "/ainmean-sgriobhte/no-aireamh/di-chlaradh"
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
