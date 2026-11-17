class BackfillDoNotAnonymizeOnPetitions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class Petition < ActiveRecord::Base; end

  def change
    up_only do
      Petition.in_batches(of: 500) do |relation|
        relation.where(do_not_anonymize: nil).update_all(do_not_anonymize: false)
        sleep(0.01)
      end
    end
  end
end
