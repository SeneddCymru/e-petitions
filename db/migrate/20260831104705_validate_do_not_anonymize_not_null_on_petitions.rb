class ValidateDoNotAnonymizeNotNullOnPetitions < ActiveRecord::Migration[8.1]
  def up
    validate_check_constraint :petitions, name: "petitions_do_not_anonymize_null"
    change_column_null :petitions, :do_not_anonymize, false
    remove_check_constraint :petitions, name: "petitions_do_not_anonymize_null"
  end

  def down
    add_check_constraint :petitions, "do_not_anonymize IS NOT NULL", name: "petitions_do_not_anonymize_null", validate: false
    change_column_null :petitions, :do_not_anonymize, true
  end
end
