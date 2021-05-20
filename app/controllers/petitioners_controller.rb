class PetitionersController < SponsorsController
  skip_before_action :block_if_not_collecting_sponsors
  skip_before_action :redirect_to_new_sponsor_page_if_validated

  before_action :block_if_collecting_sponsors

  def verify
    @petition.validate_creator!
    @petition.increment_signature_count!

    redirect_to thank_you_petitioner_url(@signature)
  end

  def thank_you
    respond_to do |format|
      format.html
    end
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

  def retrieve_petition
    @signature = Signature.find(params[:id])
    @petition = @signature.petition
  end
end
