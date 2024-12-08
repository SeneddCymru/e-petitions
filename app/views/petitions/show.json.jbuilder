json.links do
  json.self request.url
end

json.data do
  json.partial! 'petitions/petition', petition: @petition
end
