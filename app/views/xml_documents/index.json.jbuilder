json.array! @xml_documents do |doc|
  json.extract! doc, :id, :title, :description, :device_name, :created_at, :updated_at
  if doc.xml_file.attached?
    json.file do
      json.filename doc.xml_file.filename.to_s
      json.byte_size doc.xml_file.byte_size
      json.content_type doc.xml_file.content_type
      json.url rails_blob_url(doc.xml_file, only_path: true)
      json.download_url rails_blob_path(doc.xml_file, disposition: "attachment", only_path: true)
    end
  else
    json.file nil
  end
end
