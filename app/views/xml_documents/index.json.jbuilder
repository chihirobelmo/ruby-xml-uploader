json.array! @xml_documents do |doc|
  json.id doc.id
  json.title doc.title
  json.description doc.description
  json.device_name doc.device_name
  json.username(doc.user&.username)
  json.created_at doc.created_at
  json.updated_at doc.updated_at
end
