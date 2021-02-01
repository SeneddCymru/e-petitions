class CreatePeNumberAndForeignKey < ActiveRecord::Migration[6.1]
  def change
    create_table :pe_numbers do |t|
    end

    add_reference :petitions, :pe_number, index: true, default: nil, unique: true, foreign_key: { on_delete: :cascade }
  end
end
