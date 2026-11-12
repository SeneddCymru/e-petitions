class Admin::PaperSignaturesController < Admin::AdminController
  before_action :fetch_petition
  before_action :build_paper_signatures

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @paper_signatures.save
      redirect_to admin_petition_url(@petition), notice: :paper_signatures_enqueued
    elsif @paper_signatures.errors.any?
      respond_to do |format|
        format.html { render :new }
      end
    else
      redirect_to admin_petition_url(@petition), alert: :paper_signatures_not_enqueued
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def build_paper_signatures
    if action_name == "new"
      @paper_signatures = PaperSignatures.new(@petition, request.remote_ip)
    else
      @paper_signatures = PaperSignatures.new(@petition, request.remote_ip, paper_signatures_params)
    end
  end

  def paper_signatures_params
    params.require(:paper_signatures).permit(:location_code, :signature_count)
  end
end
