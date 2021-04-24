class AddIndexOnOpenAtAndCreatedAtToPetitions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_open_at_and_created_at ON petitions (open_at DESC, created_at DESC);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS
      index_petitions_on_open_at_and_created_at;
    SQL
  end
end
