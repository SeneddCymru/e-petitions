require 'rails_helper'

RSpec.describe 'Requests for an unknown format', type: :request, show_exceptions: true do
  before do
    get "/petitions/PE100001.please"
  end

  it "redirect to the path without the extension" do
    expect(response).to redirect_to('/petitions/PE100001')
  end
end
