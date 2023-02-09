class ReassignCollectingSignaturePetitionsToUnderConsideration < ActiveRecord::Migration[6.1]
  def change
    up_only do 
      execute <<~SQL
        UPDATE petitions
        SET referred_at = COALESCE(referred_at, open_at)
        WHERE open_at IS NOT NULL;
      SQL

      execute <<~SQL
        UPDATE petitions
        SET collect_signatures = true
        WHERE state IN ('pending', 'validated', 'sponsored', 'flagged', 'open')
        AND collect_signatures = false;
      SQL
    end
  end
end
