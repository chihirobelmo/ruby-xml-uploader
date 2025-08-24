class CreateXmlDownloads < ActiveRecord::Migration[7.1]
  def change
    create_table :xml_downloads do |t|
      t.references :xml_document, null: false, foreign_key: true, index: true
      t.references :user, null: true, foreign_key: true, index: true
      t.string :ip, null: true
      t.string :user_agent, null: true
      t.string :session_id, null: true
      t.timestamps
    end

    add_index :xml_downloads, [:xml_document_id, :created_at]
  end
end
