docs = Array(@xml_documents)
# Keep the latest by created_at for each [user, title, device_name]
docs = docs.sort_by { |d| d.created_at || Time.at(0) }.reverse
docs = docs.uniq { |d| [d.user_id, d.title, d.device_name] }

# Precompute total downloads per [user_id, title, device_name]
totals = XmlDownload
  .joins(:xml_document)
  .group("xml_documents.user_id", "xml_documents.title", "xml_documents.device_name")
  .count

# Sort by download_count desc, tie-breaker by created_at desc
sorted_docs = docs.sort_by do |d|
  count = totals[[d.user_id, d.title, d.device_name]] || 0
  [-count, -(d.created_at || Time.at(0)).to_i]
end

json.array! sorted_docs do |doc|
  json.id doc.id
  json.title doc.title
  json.description doc.description
  json.device_name doc.device_name
  json.username(doc.user&.username)
  json.download_count(totals[[doc.user_id, doc.title, doc.device_name]] || 0)
  json.created_at doc.created_at
  json.updated_at doc.updated_at
end
