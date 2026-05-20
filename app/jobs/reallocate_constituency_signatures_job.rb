class ReallocateConstituencySignaturesJob < ApplicationJob
  def perform(petition)
    petition.constituency_petition_journals.delete_all

    petition.signatures.find_each do |signature|
      next unless signature.united_kingdom?
      next unless signature.postcode?

      if new_constituency = Constituency.find_by_postcode(signature.postcode)
        signature.update_column(:constituency_id, new_constituency.id)
      end
    end

    ConstituencyPetitionJournal.reset_signature_counts_for(petition)
  end
end
