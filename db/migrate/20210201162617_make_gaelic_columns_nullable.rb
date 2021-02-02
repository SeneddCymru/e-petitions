class MakeGaelicColumnsNullable < ActiveRecord::Migration[6.1]
  def change
    change_column_null :petition_emails, :subject_gd, true
    change_column_null :rejection_reasons, :description_gd, true
    change_column_null :topics, :code_gd, true
    change_column_null :topics, :name_gd, true
  end
end
