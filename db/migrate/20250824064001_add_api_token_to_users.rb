class AddApiTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :api_token_digest, :string
    add_index :users, :api_token_digest, unique: true
    add_column :users, :api_token_generated_at, :datetime
  end
end
