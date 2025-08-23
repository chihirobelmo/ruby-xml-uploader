class AddUserToXmlDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :xml_documents, :user, foreign_key: true, index: true, null: true
  end
end
