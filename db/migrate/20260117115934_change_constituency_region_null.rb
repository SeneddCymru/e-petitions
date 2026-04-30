class ChangeConstituencyRegionNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :constituencies, :region_id, true
  end
end
