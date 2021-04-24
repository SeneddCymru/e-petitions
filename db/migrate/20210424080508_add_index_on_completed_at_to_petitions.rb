class AddIndexOnCompletedAtToPetitions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_completed_at ON petitions (completed_at DESC);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS
      index_petitions_on_completed_at;
    SQL
  end
end
