class AddDeviceNameToXmlDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :xml_documents, :device_name, :string
    add_index :xml_documents, :device_name
  end
end
