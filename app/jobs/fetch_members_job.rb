require 'faraday'

class FetchMembersJob < ApplicationJob
  HOST = "https://business.senedd.wales"
  TIMEOUT = 5

  ENDPOINTS = {
    "en-GB": "/mgwebservice.asmx/GetCouncillorsByWard",
    "cy-GB": "/mgwebservicew.asmx/GetCouncillorsByWard"
  }

  CONSTITUENCIES = "/councillorsbyward/wards/ward"
  CONSTITUENCY_NAME = ".//wardtitle"
  MEMBERS = ".//councillor"
  MEMBER_ID = ".//councillorid"
  MEMBER_NAME = ".//fullusername"
  PARTY_NAME = ".//politicalpartytitle"

  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  before_perform do
    @translated_members = load_translated_members
  end

  def perform
    return if @translated_members.empty?

    Member.transaction do
      Member.update_all(region_id: nil, constituency_id: nil)

      @translated_members.each do |id, attributes|
        retried = false

        begin
          Member.for(id) { |member| member.update!(attributes) }
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

  def load_translated_members
    {}.tap do |hash|
      members(:"en-GB").each do |member|
        hash[member[:id]] = {}.tap do |row|
          row[:name_en] = member[:name]
          row[:party_en] = member[:party]
          row[:constituency_id] = member[:constituency_id]
        end
      end

      members(:"cy-GB").each do |member|
        hash.fetch(member[:id]).tap do |row|
          row[:name_cy] = member[:name]
          row[:party_cy] = member[:party]
        end
      end
    end
  end

  def members(locale)
    I18n.with_locale(locale) { load_members }
  end

  def constituency_maps
    @constituency_maps ||= {}
  end

  def constituency_map
    constituency_maps[I18n.locale] ||= normalize_map(Constituency.pluck(:name, :id))
  end

  def load_members
    response = fetch_members

    if response.success?
      parse(response.body)
    else
      []
    end
  rescue Faraday::Error => e
    Appsignal.send_exception(e)
    return []
  end

  def parse(body)
    root = Nokogiri::XML(body)

    parse_constituencies(root) do |node, members|
      members.concat(parse_constituency(node))
    end
  end

  def parse_constituencies(root, &block)
    root.xpath(CONSTITUENCIES).each_with_object([], &block)
  end

  def parse_constituency(node)
    constituency_name = node.at_xpath(CONSTITUENCY_NAME).text.strip
    constituency_id = constituency_map.fetch(constituency_name.parameterize)

    parse_members(node) do |node, members|
      members << parse_member(node, constituency_id)
    end
  end

  def parse_members(node, &block)
    node.xpath(MEMBERS).each_with_object([], &block)
  end

  def parse_member(node, constituency_id)
    id = Integer(node.at_xpath(MEMBER_ID).text)
    name = node.at_xpath(MEMBER_NAME).text.strip
    party = node.at_xpath(PARTY_NAME).text.strip.tr("-", "\u2011")

    { id: id, name: name, party: party, constituency_id: constituency_id }
  end

  def faraday
    Faraday.new(HOST) do |f|
      f.response :follow_redirects
      f.response :raise_error
      f.adapter :net_http_persistent
    end
  end

  def fetch_members
    faraday.get(endpoint) do |request|
      request.options[:timeout] = TIMEOUT
      request.options[:open_timeout] = TIMEOUT
    end
  end

  def endpoint
    ENDPOINTS[I18n.locale]
  end

  def normalize_map(mappings)
    mappings.map { |key, id| [key.parameterize, id] }.to_h
  end
end
