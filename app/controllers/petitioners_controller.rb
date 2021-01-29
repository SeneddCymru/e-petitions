class PetitionersController < SponsorsController
  before_action :block_if_collecting_sponsors

  def verify
    @petition.validate_creator!

    redirect_to moderation_info_petition_url(@petition)
  end

  private

  def block_if_collecting_sponsors
    if Site.collecting_sponsors?
      raise ActionController::RoutingError, "Not available when collecting sponsors"
    end
  end

  def retrieve_signature
    @signature = Signature.find(signature_id)
    @petition = @signature.petition
  end
end
