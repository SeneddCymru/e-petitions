class AddStartAndEndDatesToRegions < ActiveRecord::Migration[8.1]
  def change
    add_column :regions, :start_date, :date
    add_column :regions, :end_date, :date

    up_only do
      safety_assured do
        execute <<~SQL
          UPDATE regions SET start_date = '2007-05-03', end_date = '2026-05-06'
        SQL
      end
    end
  end
end
