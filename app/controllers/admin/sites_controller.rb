class Admin::SitesController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_site

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @site.update(site_params)
      redirect_to edit_admin_site_url(tab: params[:tab]), notice: :site_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def fetch_site
    @site = Site.instance
  end

  def site_params
    params.require(:site).permit(
      :title_en, :title_gd, :url_en, :url_gd, :email_from_en, :email_from_gd,
      :username, :password, :enabled, :protected, :petition_duration,
      :minimum_number_of_sponsors, :maximum_number_of_sponsors,
      :threshold_for_moderation, :threshold_for_referral, :threshold_for_debate,
      :feedback_email, :moderate_url, :login_timeout, :disable_constituency_api,
      :signature_count_interval, :update_signature_counts,
      :disable_trending_petitions, :threshold_for_moderation_delay,
      :disable_invalid_signature_count_check, :disable_daily_update_statistics_job,
      :disable_plus_address_check, :disable_feedback_sending, :show_holding_page,
      :disable_gaelic_website, :disable_notify_by_email
    )
  end
end
