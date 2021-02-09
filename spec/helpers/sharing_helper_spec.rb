require 'rails_helper'

RSpec.describe SharingHelper, type: :helper do
  let(:petition) { FactoryBot.create(:open_petition, id: 100000, action_en: "Do Something!", action_gd: "Dèan Rudeigin!") }
  let(:headers) { helper.request.env }

  before do
    headers["HTTPS"]       = "on"
    headers["SERVER_PORT"] = 443
  end

  context "when viewing the site in English" do
    before do
      headers["HTTP_HOST"]   = "petitions.parliament.scot"
      I18n.locale = :"en-GB"
    end

    describe "#share_via_facebook" do
      it "generates a share via Facebook link" do
        expect(helper.share_via_facebook(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="https://www.facebook.com/sharer/sharer.php?ref=responsive&amp;u=https%3A%2F%2Fpetitions.parliament.scot%2Fpetitions%2F#{petition.to_param}">Facebook</a>
        URL
      end
    end

    describe "#share_via_email" do
      it "generates a share via email link" do
        expect(helper.share_via_email(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="mailto:?body=https%3A%2F%2Fpetitions.parliament.scot%2Fpetitions%2F#{petition.to_param}&amp;subject=Petition%3A%20Do%20Something%21">Email</a>
        URL
      end
    end

    describe "#share_via_twitter" do
      it "generates a share via Twitter link" do
        expect(helper.share_via_twitter(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="https://twitter.com/intent/tweet?text=Petition%3A%20Do%20Something%21&amp;url=https%3A%2F%2Fpetitions.parliament.scot%2Fpetitions%2F#{petition.to_param}">Twitter</a>
        URL
      end
    end

    describe "#share_via_whatsapp" do
      it "generates a share via Whatsapp link" do
        expect(helper.share_via_whatsapp(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="whatsapp://send?text=Petition%3A%20Do%20Something%21%0Ahttps%3A%2F%2Fpetitions.parliament.scot%2Fpetitions%2F#{petition.to_param}">Whatsapp</a>
        URL
      end
    end
  end

  context "when viewing the site in Gaelic" do
    before do
      headers["HTTP_HOST"]   = "athchuingean.parlamaid-alba.scot"
      I18n.locale = :"gd-GB"
    end

    describe "#share_via_facebook" do
      it "generates a share via Facebook link" do
        expect(helper.share_via_facebook(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="https://www.facebook.com/sharer/sharer.php?ref=responsive&amp;u=https%3A%2F%2Fathchuingean.parlamaid-alba.scot%2Fathchuingean%2F#{petition.to_param}">Facebook</a>
        URL
      end
    end

    describe "#share_via_email" do
      it "generates a share via email link" do
        expect(helper.share_via_email(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="mailto:?body=https%3A%2F%2Fathchuingean.parlamaid-alba.scot%2Fathchuingean%2F#{petition.to_param}&amp;subject=Athchuinge%3A%20D%C3%A8an%20Rudeigin%21">Post-d</a>
        URL
      end
    end

    describe "#share_via_twitter" do
      it "generates a share via Twitter link" do
        expect(helper.share_via_twitter(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="https://twitter.com/intent/tweet?text=Athchuinge%3A%20D%C3%A8an%20Rudeigin%21&amp;url=https%3A%2F%2Fathchuingean.parlamaid-alba.scot%2Fathchuingean%2F#{petition.to_param}">Twitter</a>
        URL
      end
    end

    describe "#share_via_whatsapp" do
      it "generates a share via Whatsapp link" do
        expect(helper.share_via_whatsapp(petition)).to eq <<-URL.strip
          <a rel="external" target="_blank" href="whatsapp://send?text=Athchuinge%3A%20D%C3%A8an%20Rudeigin%21%0Ahttps%3A%2F%2Fathchuingean.parlamaid-alba.scot%2Fathchuingean%2F#{petition.to_param}">Whatsapp</a>
        URL
      end
    end
  end
end
