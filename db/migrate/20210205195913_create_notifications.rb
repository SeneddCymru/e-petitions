class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.string :to, null: false
      t.uuid :template_id, null: false
      t.string :reference, null: false, limit: 100
      t.string :message_id, limit: 100
      t.jsonb :personalisation, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :events, null: false, default: {}
      t.timestamps null: false
      t.index :reference
      t.index :message_id, unique: true
      t.index :template_id
      t.index :status
      t.index :created_at
    end
  end
end
