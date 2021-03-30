json.data trending_petitions(limit: 10) do |id, action, count|
  json.type "petition"
  json.id "PE%04d" % id

  json.links do
    json.self petition_url("PE%04d" % id, :json)
  end

  json.attributes do
    json.action action
    json.signature_count count
  end
end

json.links do
  json.self trending_url(:json)
end

json.meta do
  json.updated_at api_date_format(trending_petitions_at)
end
