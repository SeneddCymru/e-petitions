class ChangeMembersConstituencyUniqueIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    with_options algorithm: :concurrently do
      remove_index :members, :constituency_id, unique: true
      add_index :members, :constituency_id
    end
  end
end
