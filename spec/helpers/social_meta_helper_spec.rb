require 'rails_helper'

RSpec.describe SocialMetaHelper, type: :helper do
  let(:headers) { helper.request.env }

  describe "#open_graph_tag" do
    context "when using a string for content" do
      subject do
        helper.open_graph_tag("type", "article")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta property="og:type" content="article" />})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.open_graph_tag("site_name", :site_name)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:site_name" content="Petitions - Senedd" />})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.open_graph_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:title" content="Petition: Show us the money" />})
      end
    end

    context "when using a image path for content" do
      before do
        headers["HTTP_HOST"]   = "petitions.senedd.wales"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      subject do
        helper.open_graph_tag("image", "os-social/opengraph-image.png")
      end

      it "generates a meta tag with the correct asset image url" do
        expect(subject).to match(%r{<meta property="og:image" content="https://petitions.senedd.wales/assets/os-social/opengraph-image.png" />})
      end
    end
  end

  describe "#twitter_card_tag" do
    context "when using a string for content" do
      subject do
        helper.twitter_card_tag("site", "@WelshPetitions")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta name="twitter:site" content="@WelshPetitions" />})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.twitter_card_tag("title", :default_title)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petitions - Senedd" />})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.twitter_card_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petition: Show us the money" />})
      end
    end

    context "when using a image path for content" do
      before do
        headers["HTTP_HOST"]   = "petitions.senedd.wales"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      subject do
        helper.twitter_card_tag("image", "os-social/twitter-image.png")
      end

      it "generates a meta tag with the correct asset image url" do
        expect(subject).to match(%r{<meta name="twitter:image" content="https://petitions.senedd.wales/assets/os-social/twitter-image.png" />})
      end
    end
  end
end
