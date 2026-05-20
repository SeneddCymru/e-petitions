class ReallocateConstituencySignaturesJob < ApplicationJob
  def perform(petition, time = current_time)
    signatures(petition).find_each do |signature|
      next unless signature.united_kingdom?
      next unless signature.postcode?

      if new_constituency = Constituency.find_by_postcode(signature.postcode)
        signature.update_column(:constituency_id, new_constituency.id)
      end
    end

    ConstituencyPetitionJournal.reset_signature_counts_for(petition)
  end

  private

  def current_time
    Time.current.change(usec: 0).iso8601
  end

  def signatures(petition)
    petition.signatures.validated
  end
end
