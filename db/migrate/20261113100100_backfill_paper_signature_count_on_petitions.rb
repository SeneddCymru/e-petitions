class BackfillPaperSignatureCountOnPetitions < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL
        UPDATE petitions
        SET paper_signature_count = paper_signatures.count
        FROM (
          SELECT petition_id, COUNT(*) AS count
          FROM signatures
          WHERE postcode = 'ZZ993WZ'
          GROUP BY petition_id
        ) AS paper_signatures
        WHERE petitions.id = paper_signatures.petition_id
      SQL
    end
  end

  def down
    # Nothing to do
  end
end
