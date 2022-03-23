json.cache! [I18n.locale, :regions, :geojson], expires_in: 1.hour do
  json.type "FeatureCollection"

  json.features @regions do |region|
    json.type "Feature"

    json.properties do
      json.id region.id
      json.name region.name
      json.members region.members do |member|
        json.name member.name
        json.party member.party
        json.url member.url
      end
    end

    json.geometry RGeo::GeoJSON.encode(region.boundary)
  end
end