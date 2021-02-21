class ReferOrRejectPetitionsJob < ApplicationJob
  queue_as :high_priority

  def perform(time)
    unless Site.disable_thresholds_and_debates?
      Petition.refer_or_reject_petitions!(time.in_time_zone)
    end
  end
end
