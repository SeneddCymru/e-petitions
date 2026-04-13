json.array! @constituencies do |constituency|
  json.id constituency.id
  json.name constituency.name
  json.population constituency.population

  json.members constituency.members do |member|
    json.name member.name
    json.party member.party
    json.url member.url
  end

  if region = constituency.region
    json.region do
      json.id region.id
      json.name region.name
      json.population region.population

      json.members region.members do |member|
        json.name member.name
        json.party member.party
        json.url member.url
      end
    end
  else
    json.region nil
  end
end
