class AddPreviousActionToPetition < ActiveRecord::Migration[6.1]
  def change
    add_column :petitions, :previous_action_en, :text
    add_column :petitions, :previous_action_gd, :text
  end
end
