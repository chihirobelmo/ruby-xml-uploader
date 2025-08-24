docs = Array(@xml_documents)
# Keep the latest by created_at for each [user, title, device_name]
docs = docs.sort_by { |d| d.created_at || Time.at(0) }.reverse
docs = docs.uniq { |d| [d.user_id, d.title, d.device_name] }

json.array! docs do |doc|
  json.id doc.id
  json.title doc.title
  json.description doc.description
  json.device_name doc.device_name
  json.username(doc.user&.username)
  json.created_at doc.created_at
  json.updated_at doc.updated_at
end
