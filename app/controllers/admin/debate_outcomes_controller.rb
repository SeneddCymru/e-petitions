class Admin::DebateOutcomesController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_debate_outcome

  rescue_from ActiveRecord::RecordNotUnique do
    @debate_outcome = @petition.reload_debate_outcome and update
  end

  def show
    render 'admin/petitions/show'
  end

  def update
    if @debate_outcome.update(debate_outcome_params)
      if send_email_to_petitioners?
        EmailDebateOutcomesJob.run_later_tonight(petition: @petition)
        message = :email_sent_overnight
      else
        message = :debate_outcome_updated
      end

      redirect_to [:admin, @petition], notice: message
    else
      render 'admin/petitions/show', alert: :debate_outcome_not_saved
    end
  end

  private

  def fetch_petition
    @petition = Petition.debateable.find(params[:petition_id])
  end

  def fetch_debate_outcome
    @debate_outcome = @petition.debate_outcome || @petition.build_debate_outcome
  end

  def debate_outcome_params
    params.require(:debate_outcome).permit(*debate_outcome_attributes)
  end

  def debate_outcome_attributes
    %i[
      debated_on debated image
      overview_en transcript_url_en video_url_en debate_pack_url_en
      overview_cy transcript_url_cy video_url_cy debate_pack_url_cy
    ]
  end

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end
end
