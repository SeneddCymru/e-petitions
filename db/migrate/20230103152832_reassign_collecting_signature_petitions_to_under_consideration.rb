class ReassignCollectingSignaturePetitionsToUnderConsideration < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE petitions
      SET referred_at = open_at, referral_threshold_reached_at = open_at
      WHERE referred_at IS NULL
      AND open_at IS NOT NULL;"
    )

    execute(
      "UPDATE petitions
      SET collect_signatures = true
      WHERE (state = 'pending'
        OR state = 'validated'
        OR state = 'sponsored'
        OR state = 'flagged'
        OR state = 'opened')
      AND collect_signatures = false"
    )
  end

  def down; end
end
