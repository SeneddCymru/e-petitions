require 'rails_helper'

RSpec.describe "routes for admin petition content", type: :routes, admin: true do
  it "doesn't route GET /admin/petitions/1/content/new" do
    expect(get("/admin/petitions/1/content/new")).not_to be_routable
  end

  it "routes POST /admin/petitions/1/content to admin/content#create" do
    expect(post("/admin/petitions/1/content")).to route_to('admin/content#create', petition_id: '1')
  end

  it "doesn't route GET /admin/petitions/1/content" do
    expect(get("/admin/petitions/1/content")).not_to be_routable
  end

  it "doesn't route GET /admin/petitions/1/content/edit" do
    expect(post("/admin/petitions/1/content/edit")).not_to be_routable
  end

  it "doesn't route PATCH /admin/petitions/1/content" do
    expect(patch("/admin/petitions/1/content")).not_to be_routable
  end

  it "routes DELETE /admin/petitions/1/content to admin/completion#destroy" do
    expect(delete("/admin/petitions/1/content")).to route_to('admin/content#destroy', petition_id: '1')
  end
end
