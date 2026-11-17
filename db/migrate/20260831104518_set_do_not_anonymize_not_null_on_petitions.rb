class SetDoNotAnonymizeNotNullOnPetitions < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :petitions, "do_not_anonymize IS NOT NULL", name: "petitions_do_not_anonymize_null", validate: false
  end
end
