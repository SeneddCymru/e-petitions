class UnsetClosedAtDateOnOpenPetitions < ActiveRecord::Migration[6.1]
  def change
    up_only do 
      execute <<~SQL
        UPDATE petitions
        SET closed_at = NULL
        WHERE state IN ('pending', 'validated', 'sponsored', 'flagged', 'open', 'closed')
      SQL

      execute <<~SQL
        UPDATE petitions
        SET state = 'open'
        WHERE state = 'closed'
      SQL
    end
  end
end
