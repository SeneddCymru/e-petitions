json.array! @regions do |region|
  json.id region.id
  json.name region.name
  json.population region.population

  json.members region.members do |member|
    json.name member.name
    json.party member.party
    json.url member.url
  end
end
