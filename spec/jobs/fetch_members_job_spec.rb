require 'rails_helper'

RSpec.describe FetchMembersJob, type: :job do
  let(:url) { "https://data.parliament.scot" }

  let(:constituencies_api) { "#{url}/api/Constituencies" }
  let(:constituency_elections_api) { "#{url}/api/MemberElectionConstituencyStatuses" }
  let(:member_parties_api) { "#{url}/api/MemberParties" }
  let(:members_api) { "#{url}/api/Members" }
  let(:parties_api) { "#{url}/api/Parties" }
  let(:regions_api) { "#{url}/api/Regions" }
  let(:region_elections_api) { "#{url}/api/MemberElectionRegionStatuses" }

  let(:stub_constituencies_api) { stub_request(:get, constituencies_api) }
  let(:stub_constituency_elections_api) { stub_request(:get, constituency_elections_api) }
  let(:stub_member_parties_api) { stub_request(:get, member_parties_api) }
  let(:stub_members_api) { stub_request(:get, members_api) }
  let(:stub_parties_api) { stub_request(:get, parties_api) }
  let(:stub_regions_api) { stub_request(:get, regions_api) }
  let(:stub_region_elections_api) { stub_request(:get, region_elections_api) }

  def json_response(status, body = nil, &block)
    message = status.to_s.titleize
    status = Rack::Utils.status_code(status)
    headers = { "Content-Type" => "application/json; charset=utf-8" }

    if block_given?
      body = block.call
    elsif body
      body = file_fixture("#{body}.json").read
    else
      body = %[{ "error": { "code": #{status}, "message": "#{message}" } }]
    end

    { status: status, headers: headers, body: body }
  end

  before do
    FactoryBot.create(:constituency, :glasgow_provan)
  end

  context "when the request is successful" do
    before do
      stub_constituencies_api.to_return(json_response(:ok, "constituencies"))
      stub_constituency_elections_api.to_return(json_response(:ok, "constituency_elections"))
      stub_member_parties_api.to_return(json_response(:ok, "member_parties"))
      stub_members_api.to_return(json_response(:ok, "members"))
      stub_parties_api.to_return(json_response(:ok, "parties"))
      stub_regions_api.to_return(json_response(:ok, "regions"))
      stub_region_elections_api.to_return(json_response(:ok, "region_elections"))
    end

    it "imports members" do
      expect {
        described_class.perform_now
      }.to change {
        Member.count
      }.from(0).to(8)
    end

    describe "attribute assignment" do
      let(:member) { Member.find(5612) }
      let(:members) { Member.pluck(:name_en) }

      before do
        described_class.perform_now
      end

      it "imports members" do
        expect(members).to include("Ivan McKee MSP")
        expect(members).to include("Adam Tomkins MSP")
        expect(members).to include("Anas Sarwar MSP")
        expect(members).to include("Annie Wells MSP")
        expect(members).to include("James Kelly MSP")
        expect(members).to include("Johann Lamont MSP")
        expect(members).to include("Patrick Harvie MSP")
        expect(members).to include("Pauline McNeill MSP")
      end

      it "assigns the member id" do
        expect(member.id).to eq(5612)
      end

      it "assigns the English member name" do
        expect(member.name_en).to eq("Ivan McKee MSP")
      end

      it "assigns the Gaelic member name" do
        expect(member.name_gd).to eq("Ivan McKee BPA")
      end

      it "assigns the English party name" do
        expect(member.party_en).to eq("Scottish National Party")
      end

      it "assigns the Gaelic party name" do
        expect(member.party_gd).to eq("Pàrtaidh Nàiseanta na h-Alba")
      end
    end

    describe "association assignment" do
      context "for a constituency member" do
        let(:member) { Member.find(5612) }

        before do
          described_class.perform_now
        end

        it "assigns the correct constituency" do
          expect(member.constituency_name).to eq("Glasgow Provan")
        end
      end

      context "for a regional member" do
        let(:member) { Member.find(5586) }

        before do
          described_class.perform_now
        end

        it "assigns the correct region" do
          expect(member.region_name).to eq("Glasgow")
        end
      end
    end

    describe "error handling" do
      context "when a record fails to save" do
        let!(:member) { FactoryBot.create(:member, :glasgow_provan) }
        let(:exception) { ActiveRecord::RecordInvalid.new(member) }

        before do
          allow(Member).to receive(:find_or_initialize_by).and_call_original
        end

        it "notifies Appsignal of the failure" do
          expect(Member).to receive(:find_or_initialize_by).with(id: 5612).and_return(member)
          expect(member).to receive(:save!).and_raise(exception)
          expect(Appsignal).to receive(:send_exception).with(exception)

          described_class.perform_now
        end
      end
    end

    describe "updating members" do
      context "when a member is still in office" do
        let!(:member) { FactoryBot.create(:member, :glasgow_provan, name: "Paul Martin MSP") }

        it "updates the record" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.name
          }.from("Paul Martin MSP").to("Ivan McKee MSP")
        end
      end

      context "when a constituency member is no longer in office" do
        let!(:member) { FactoryBot.create(:member, :constituency_member) }

        it "clears the constituency association" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.constituency_id
          }.from("S16000075").to(nil)
        end
      end

      context "when a regional member is no longer in office" do
        let!(:member) { FactoryBot.create(:member, :regional_member) }

        it "clears the region association" do
          expect {
            described_class.perform_now
          }.to change {
            member.reload.region_id
          }.from("S17000015").to(nil)
        end
      end
    end
  end

  context "when the request is unsuccessful" do
    context "because the API is not responding" do
      before do
        stub_members_api.to_timeout
      end

      it "doesn't import any members" do
        expect { described_class.perform_now }.not_to change { Member.count }
      end
    end

    context "because the API connection is blocked" do
      before do
        stub_members_api.to_return(json_response(:proxy_authentication_required))
      end

      it "doesn't import any members" do
        expect { described_class.perform_now }.not_to change { Member.count }
      end
    end

    context "because the API can't be found" do
      before do
        stub_members_api.to_return(json_response(:not_found))
      end

      it "doesn't import any members" do
        expect { described_class.perform_now }.not_to change { Member.count }
      end
    end

    context "because the API can't find the resource" do
      before do
        stub_members_api.to_return(json_response(:not_acceptable))
      end

      it "doesn't import any members" do
        expect { described_class.perform_now }.not_to change { Member.count }
      end
    end

    context "because the API is returning an internal server error" do
      before do
        stub_members_api.to_return(json_response(:internal_server_error))
      end

      it "doesn't import any members" do
        expect { described_class.perform_now }.not_to change { Member.count }
      end
    end
  end
end
