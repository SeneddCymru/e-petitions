json.array! @countries do |country|
  json.id country.id
  json.name country.name
  json.population country.population
end
