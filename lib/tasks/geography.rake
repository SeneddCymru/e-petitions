require 'csv'

namespace :spets do
  namespace :geography do
    desc "Load constituency, postcode and region data"
    task import: :environment do
      region = Class.new(ActiveRecord::Base) { self.table_name = "regions" }
      file = Rails.root.join("data", "regions.csv")

      CSV.foreach(file, headers: true).each do |row|
        region.create!(row.to_h)
      end

      constituency = Class.new(ActiveRecord::Base) { self.table_name = "constituencies" }
      file = Rails.root.join("data", "constituencies.csv")

      CSV.foreach(file, headers: true).each do |row|
        constituency.create!(row.to_h)
      end

      # Use the underlying pg gem in a more efficient manner to insert postcodes
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare("insert_postcode", "INSERT INTO postcodes VALUES ($1, $2)")

      file = Rails.root.join("data", "postcodes.csv")

      CSV.foreach(file, headers: true) do |row|
        conn.exec_prepared("insert_postcode", row.fields)
      end
    end

    task update_constituencies: :environment do
      # Have to drop down to SQL to handle the timestamps
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare "update_constituencies", <<~SQL
        INSERT INTO constituencies VALUES ($1, $2, $3, $4, $5, $6, $6)
        ON CONFLICT (id) DO UPDATE
        SET region_id = EXCLUDED.region_id,
            name_en = EXCLUDED.name_en,
            name_gd = EXCLUDED.name_gd,
            example_postcode = EXCLUDED.example_postcode,
            updated_at = EXCLUDED.updated_at
      SQL

      file = Rails.root.join("data", "constituencies.csv")

      CSV.foreach(file, headers: true).each do |row|
        conn.exec_prepared("update_constituencies", row.fields + [Time.current.iso8601(6)])
      end
    end

    task update_regions: :environment do
      # Have to drop down to SQL to handle the timestamps
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare "update_region", <<~SQL
        INSERT INTO regions VALUES ($1, $2, $3, $4, $4)
        ON CONFLICT (id) DO UPDATE
        SET name_en = EXCLUDED.name_en,
            name_gd = EXCLUDED.name_gd,
            updated_at = EXCLUDED.updated_at
      SQL

      file = Rails.root.join("data", "regions.csv")

      CSV.foreach(file, headers: true).each do |row|
        conn.exec_prepared("update_region", row.fields + [Time.current.iso8601(6)])
      end
    end

    task update_postcodes: :environment do
      # Use the underlying pg gem in a more efficient manner to update postcodes
      conn = ActiveRecord::Base.connection.raw_connection
      conn.prepare "update_postcode", <<~SQL
        INSERT INTO postcodes VALUES ($1, $2)
        ON CONFLICT (id) DO UPDATE
        SET constituency_id = EXCLUDED.constituency_id
      SQL

      file = Rails.root.join("data", "postcodes.csv")

      CSV.foreach(file, headers: true) do |row|
        conn.exec_prepared("update_postcode", row.fields)
      end
    end
  end
end
