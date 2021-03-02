class CreateTemplates < ActiveRecord::Migration[6.1]
  def change
    enable_extension :pgcrypto

    create_table :templates, id: :uuid do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.text :body, null: false

      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
