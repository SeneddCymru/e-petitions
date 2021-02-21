class Admin::ContentController < Admin::AdminController
  before_action :fetch_petition, only: [:create, :destroy]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to admin_root_url, alert: "Sorry, we couldn't find petition #{params[:petition_id]}"
  end

  def create
    @petition.copy_content!

    redirect_to admin_petition_url(@petition), notice: :petition_content_copied
  end

  def destroy
    @petition.reset_content!

    redirect_to admin_petition_url(@petition), notice: :petition_content_reset
  end

  protected

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end
end
