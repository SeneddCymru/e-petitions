class AddForeignKeyToConstituencyRegion < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :constituencies, :regions, validate: false
  end
end
