json.constituency do
  json.id @constituency.id
  json.name @constituency.name

  json.members @members do |member|
    json.name member.name
    json.party member.party
    json.url member.url
  end

  json.region do
    json.id @region.id
    json.name @region.name

    json.members @regional_members do |member|
      json.name member.name
      json.party member.party
      json.url member.url
    end
  end
end

json.petitions @petitions do |petition|
  json.action petition.action
  json.url petition_url(petition)
  json.state petition.state
  json.constituency_signature_count petition.constituency_signature_count
  json.total_signature_count petition.signature_count
end
