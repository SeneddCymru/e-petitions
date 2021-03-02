class AddFullTextIndexesToNotifications < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :notifications, %[to_tsvector('simple'::regconfig, "to"::text)], name: "ft_index_notifications_on_to", using: :gin, algorithm: :concurrently
    add_index :notifications, %[to_tsvector('simple'::regconfig, "reference"::text)], name: "ftindex_notifications_on_reference", using: :gin, algorithm: :concurrently
  end
end
