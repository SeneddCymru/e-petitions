class Admin::CompletionDateController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update(petition_params)
      redirect_to [:admin, @petition], notice: :completion_date_updated
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.find_by_param!(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(:completed_at)
  end
end
