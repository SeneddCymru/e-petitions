class AddDoNotAnonymizeToPetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :petitions, :do_not_anonymize, :boolean
    change_column_default :petitions, :do_not_anonymize, false
  end
end
