class AllowNullMemberParty < ActiveRecord::Migration[5.2]
  def change
    change_column_null :members, :party_en, true
    change_column_null :members, :party_gd, true
  end
end
