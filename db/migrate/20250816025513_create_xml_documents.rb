class CreateXmlDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :xml_documents do |t|
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
