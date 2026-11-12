class AddPaperSignaturesJob < ApplicationJob
  queue_as :high_priority

  POSTCODE = "ZZ993WZ"

  # Don't retry on failure otherwise signatures that were
  # added before the error would be added a second time
  rescue_from(StandardError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(petition, location_code, signature_count, ip_address)
    signature_count.times do |index|
      number = index + 1

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
  end
end
