class DefaultPetitionCollectin < ActiveRecord::Migration[6.1]
  def change
    change_column_default :petitions, :collect_signatures, true
  end
end
