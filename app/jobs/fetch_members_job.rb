require 'faraday'

class FetchMembersJob < ApplicationJob
  HOST = "https://data.parliament.scot"
  TIMEOUT = 5

  ENDPOINTS = {
    constituencies: "/api/Constituencies",
    constituency_elections: "/api/MemberElectionConstituencyStatuses",
    member_parties: "/api/MemberParties",
    members: "/api/Members",
    parties: "/api/Parties",
    regions: "/api/Regions",
    region_elections: "/api/MemberElectionRegionStatuses"
  }

  NAME_PATTERN = /,\s+/

  # The constituencies endpoint currently returns incorrect codes
  # for 'Glasgow Provan' and 'Strathkelvin and Bearsden' so we need
  # to map those to the correct ONS codes
  CONSTITUENCY_FIXES = {
    "S16000120" => "S16000147",
    "S16000145" => "S16000148"
  }

  # The regions endpoint currently returns incorrect codes for 'Glasgow'
  # so we need to map that to the correct ONS code
  REGION_FIXES = {
    "S17000010" => "S17000017"
  }

  # The 'Reform UK' party doesn't appear in the parties endpoint so
  # we need to add it to the list manually for now.
  ADDITIONAL_PARTIES = {
    13 => "Reform UK"
  }

  GAELIC_PARTIES = {
    "No Party Affiliation" => "Gun Cheangal Pàrtaidh",
    "Scottish Green Party" => "Pàrtaidh Uaine na h-Alba",
    "Independent" => "Neo-eisimeileach",
    "Scottish National Party" => "Pàrtaidh Nàiseanta na h-Alba",
    "Scottish Conservative and Unionist Party" => "Pàrtaidh Tòraidheach na h-Alba",
    "Scottish Liberal Democrats" => "Pàrtaidh Libearal Deamocratach na h-Alba",
    "Scottish Labour" => "Pàrtaidh Làbarach na h-Alba",
    "Reform UK" => "Reform UK"
  }

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    Member.transaction do
      Member.update_all(region_id: nil, constituency_id: nil)

      members.each do |attrs|
        person_id = attrs["PersonID"]
        retried = false

        begin
          Member.for(person_id) do |member|
            last, first = attrs["ParliamentaryName"].split(NAME_PATTERN)
            party = parties[member_parties[person_id]]

            member.name_en = "#{first} #{last} MSP"
            member.name_gd = "#{first} #{last} BPA"
            member.party_en = party
            member.party_gd = GAELIC_PARTIES[party]

            if region_id = region_elections[person_id]
              member.region_id = regions.fetch(region_id)
            elsif constituency_id = constituency_elections[person_id]
              member.constituency_id = constituencies.fetch(constituency_id)
            end

            member.save!
          end
        rescue ActiveRecord::RecordNotUnique => e
          if retried
            raise e
          else
            retried = true
            retry
          end
        end
      end
    end
  end

  private

  def members
    @members ||= get(:members).select { |member| member["IsCurrent"] }
  end

  def constituencies
    @constituencies ||= build_map(:constituencies, "ID", "ConstituencyCode").transform_values(&method(:fix_constituencies))
  end

  def fix_constituencies(code)
    CONSTITUENCY_FIXES[code] || code
  end

  def constituency_elections
    @constituency_elections ||= build_map(:constituency_elections, "PersonID", "ConstituencyID")
  end

  def parties
    @parties ||= build_map(:parties, "ID", "PreferredName").merge(ADDITIONAL_PARTIES)
  end

  def member_parties
    @member_parties ||= build_map(:member_parties, "PersonID", "PartyID")
  end

  def regions
    @regions ||= build_map(:regions, "ID", "RegionCode", "EndDate").transform_values(&method(:fix_regions))
  end

  def fix_regions(code)
    REGION_FIXES[code] || code
  end

  def region_elections
    @region_elections ||= build_map(:region_elections, "PersonID", "RegionID")
  end

  def faraday
    Faraday.new(HOST) do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.response :json
      f.adapter :net_http_persistent
    end
  end

  def request(entity)
    faraday.get(ENDPOINTS[entity]) do |request|
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end

  def get(entity)
    response = request(entity)

    if response.success?
      response.body
    else
      []
    end
  rescue Faraday::Error => e
    Appsignal.send_exception(e)
    return []
  end

  def build_map(entity, id, name, ends_at = "ValidUntilDate")
    get(entity).inject({}) do |objects, object|
      if object[ends_at].nil?
        objects[object[id]] = object[name]
      end

      objects
    end
  end
end
