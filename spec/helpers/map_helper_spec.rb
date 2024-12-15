require 'rails_helper'

RSpec.describe MapHelper, type: :helper do
  let!(:petition) { FactoryBot.create(:open_petition) }
  let!(:constituency) { FactoryBot.create(:constituency, :swansea_west) }

  describe "#map_preview" do
    let(:template) do
      proc do |preview|
        preview.constituencies do |constituency|
          constituency.polygons do |polygon|
            preview.draw(polygon.path, polygon.stroke_color, polygon.fill_color)
          end
        end
      end
    end

    let(:blob) do
      helper.map_preview(petition, &template)
    end

    let(:mime_type) do
      Marcel::MimeType.for(StringIO.new(blob))
    end

    it "returns a PNG blob" do
      expect(mime_type).to eq("image/png")
    end
  end
end
