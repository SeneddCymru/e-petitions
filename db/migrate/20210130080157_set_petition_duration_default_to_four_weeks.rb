class SetPetitionDurationDefaultToFourWeeks < ActiveRecord::Migration[6.1]
  class Site < ActiveRecord::Base; end

  def change
    change_column_default :sites, :petition_duration, from: 6, to: 4

    up_only do
      Site.update_all(petition_duration: 4)
    end
  end
end
