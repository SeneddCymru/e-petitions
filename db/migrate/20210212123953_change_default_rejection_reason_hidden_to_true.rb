class ChangeDefaultRejectionReasonHiddenToTrue < ActiveRecord::Migration[6.1]
  class RejectionReason < ActiveRecord::Base; end

  def change
    change_column_default :rejection_reasons, :hidden, from: false, to: true

    up_only do
      RejectionReason.update_all(hidden: true)
    end
  end
end
