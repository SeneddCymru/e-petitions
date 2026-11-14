class AddPaperSignaturesJob < ApplicationJob
  queue_as :high_priority

  POSTCODE = "ZZ993WZ"
  MAX_ATTEMPTS = 5
  RETRY_WAIT = 1.hour

  # Don't let Delayed Job retry on failure otherwise signatures that
  # were added before the error would be added a second time
  rescue_from(StandardError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(petition, location_code, signature_count, ip_address, attempt = 1)
    added = 0

    signature_count.times do
      # The counter update locks the petition row until the transaction is
      # committed so the numbering is sequential across concurrent jobs and
      # the count is rolled back along with the signature if there's an error
      Petition.transaction do
        Petition.update_counters(petition.id, paper_signature_count: 1)
        number = Petition.where(id: petition.id).pick(:paper_signature_count)

        signature = Signature.new(
          petition: petition,
          name: "Paper Signature #{number}",
          email: EmailGenerator.call(petition.signature_count + number),
          postcode: POSTCODE,
          location_code: location_code,
          ip_address: ip_address
        )

        signature.save!
        signature.validate!(force: true)
      end

      added += 1
    end
  rescue StandardError => exception
    Appsignal.send_exception exception

    # Allow time for the error to be fixed before adding the remaining signatures
    if attempt < MAX_ATTEMPTS
      self.class.set(wait: RETRY_WAIT).perform_later(
        petition, location_code, signature_count - added, ip_address, attempt + 1
      )
    end
  end
end
