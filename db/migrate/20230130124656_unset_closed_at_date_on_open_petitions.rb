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

      ## Rerun this statement to catch those petitions that we missed when setting opening signatures first time when they were closed 
      execute <<~SQL
        UPDATE petitions
        SET collect_signatures = true
        WHERE state IN ('open')
        AND collect_signatures = false;
      SQL
    end
  end
end
