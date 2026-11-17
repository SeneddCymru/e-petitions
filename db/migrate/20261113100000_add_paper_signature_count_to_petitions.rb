class AddPaperSignatureCountToPetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :petitions, :paper_signature_count, :integer, default: 0, null: false
  end
end
